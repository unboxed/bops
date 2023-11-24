# frozen_string_literal: true

class ValidationRequest < ApplicationRecord
  VALIDATION_REQUEST_TYPES = %w[
    additional_document
    description_change
    red_line_boundary_change
    replacement_document
    fee_change
    other_change
  ].freeze

  with_options to: :planning_application do
    delegate :audits
    delegate :validated?, prefix: :planning_application
    delegate :closed_or_cancelled?, prefix: :planning_application
    delegate :reset_validation_requests_update_counter!
  end

  delegate :invalidated_document_reason, to: :old_document
  delegate :validated?, :archived?, to: :new_document, prefix: :new_document

  include Auditable

  include GeojsonFormattable

  class RecordCancelError < RuntimeError; end

  class NotDestroyableError < StandardError; end

  class CancelledEmailError < StandardError; end

  class ValidationRequestNotCreatableError < StandardError; end

  class UploadFilesError < RuntimeError; end

  belongs_to :requestable, polymorphic: true, optional: true
  belongs_to :planning_application
  belongs_to :user
  belongs_to :old_document, optional: true, class_name: "Document"
  belongs_to :new_document, optional: true, class_name: "Document"

  validates :request_type, presence: true, inclusion: {in: VALIDATION_REQUEST_TYPES}
  validates :reason, presence: true
  validates :suggestion, presence: true, if: :fee_change?
  validates :cancel_reason, presence: true, if: :cancelled?
  validates :new_geojson, presence: true, if: :red_line_boundary_change?
  validates :proposed_description, presence: true, if: :description_change?
  validate :allows_only_one_open_description_change, on: :create, if: :description_change?
  validate :planning_application_has_not_been_determined, on: :create, if: :description_change?
  validate :rejected_reason_is_present?, if: :red_line_boundary_change?
  validate :ensure_no_open_or_pending_fee_item_validation_request, on: :create, if: :fee_change?

  scope :closed, -> { where(state: "closed") }
  scope :active, -> { where.not(state: "cancelled").or(where.not(state: "closed")) }
  scope :cancelled, -> { where(state: "cancelled") }
  scope :pending, -> { where(state: "pending") }
  scope :not_cancelled, -> { where(cancelled_at: nil) }
  scope :open_or_pending, -> { open.or(pending) }
  scope :post_validation, -> { where(post_validation: true) }
  scope :open_change_created_over_5_business_days_ago, -> { open.where("created_at <= ?", 5.business_days.ago) }
  scope :pre_validation, -> { where(post_validation: false) }
  scope :overdue, -> { where(state: ["open", "overdue"]) }
  scope :responsed, -> { where.not(responded_at: nil) }
  scope :with_active_document, -> { joins(:old_document).where(documents: {archived_at: nil}) }

  store_accessor :specific_attributes, %w[new_geojson original_geojson suggestion document_request_type proposed_description previous_description]

  before_create lambda {
                  reset_validation_requests_update_counter!(request_type)
                }
  before_create :reset_replacement_document_validation_request_update_counter!, if: :replacement_document?
  before_create :set_original_geojson, if: :red_line_boundary_change?
  before_create :set_sequence
  before_create :set_previous_application_description, if: :description_change?
  before_create :ensure_planning_application_not_closed_or_cancelled!
  after_create :set_post_validation!, if: :planning_application_validated?
  after_create :email_and_timestamp, if: :pending?
  after_create :create_audit!
  before_destroy :ensure_validation_request_destroyable!
  after_destroy :reset_columns
  after_create :set_documents_missing, if: :additional_document?
  before_destroy :reset_documents_missing, if: :additional_document?

  after_create :set_invalid_payment_amount, if: :fee_change?
  before_update :reset_fee_invalidation, if: -> { closed? && fee_change? }
  before_destroy :reset_fee_invalidation, if: :fee_change?

  format_geojson_epsg :original_geojson
  format_geojson_epsg :new_geojson

  VALIDATION_REQUEST_TYPES.each do |type|
    scope "#{type.underscore}s", -> { where(request_type: type) }
  end

  include AASM

  aasm.attribute_name :state

  aasm whiny_persistence: true do
    state :pending, initial: true
    state :open
    state :closed
    state :cancelled

    event :mark_as_sent do
      transitions from: :pending, to: :open

      after do
        update!(notified_at: Time.zone.now)
      end
    end

    event :cancel do
      transitions from: %i[open pending], to: :cancelled

      after do
        reset_update_counter!
        update!(cancelled_at: Time.current)
      end
    end

    event :auto_close do
      transitions from: :open, to: :closed
    end

    event :close do
      transitions from: :open, to: :closed

      after do
        update_counter! unless post_validation?
        update!(closed_at: Time.current)
      end
    end
  end

  def response_due
    if description_change?
      5.business_days.after(created_at.to_date)
    else
      15.business_days.after(created_at.to_date)
    end
  end

  def days_until_response_due
    if response_due > Time.zone.today
      Time.zone.today.business_days_until(response_due)
    else
      -response_due.business_days_until(Time.zone.today)
    end
  end

  def overdue?
    days_until_response_due.negative?
  end

  def increment_sequence(validation_requests)
    self.sequence = validation_requests.length + 1
  end

  def set_sequence
    self.sequence = self.class.where(planning_application:).count + 1
  end

  def audit_name
    "#{model_name.human} ##{sequence}"
  end

  def can_cancel?
    may_cancel? && (planning_application.invalidated? || post_validation?)
  end

  def cancel_request!
    transaction do
      cancel!
      reset_columns
      audit!(activity_type: "#{request_type}_validation_request_#{cancel_audit_event}", activity_information: sequence,
        audit_comment: {cancel_reason:}.to_json)
    end
  rescue ActiveRecord::ActiveRecordError, AASM::InvalidTransition => e
    raise RecordCancelError, e.message
  end

  def ensure_validation_request_destroyable!
    return if pending?

    raise NotDestroyableError, "Only requests that are pending can be destroyed"
  end

  def create_api_audit!
    audit!(
      activity_type: "#{self.class.name.underscore}_received",
      activity_information: sequence.to_s,
      audit_comment: audit_api_comment
    )
  end

  def create_audit!
    event = if planning_application.not_started?
      "added"
    elsif post_validation?
      "sent_post_validation"
    else
      "sent"
    end

    create_audit_for!(event)
  end

  def can_upload?
    open? && may_close?
  end

  def upload_files!(files)
    transaction do
      files.each do |file|
        planning_application.documents.create!(file:, additional_document_validation_request: self)
      end
      close!
      audit_upload_files!
    end
  rescue ActiveRecord::ActiveRecordError, AASM::InvalidTransition => e
    raise UploadFilesError, e.message
  end

  def ensure_planning_application_not_validated!
    return unless planning_application_validated?

    raise ValidationRequestNotCreatableError,
      "Cannot create #{self.class.name.titleize} when planning application has been validated"
  end

  def ensure_planning_application_not_closed_or_cancelled!
    return unless planning_application_closed_or_cancelled?

    raise ValidationRequestNotCreatableError,
      "Cannot create #{self.class.name.titleize} when planning application has been closed or cancelled"
  end

  def open_or_pending?
    open? || pending?
  end

  def active_closed_fee_item?
    (request_type == "fee_change") && closed? && self == planning_application.validation_requests.fee_changes.not_cancelled.last
  end

  def request_expiry_date
    5.business_days.after(created_at)
  end

  def auto_close_request!
    transaction do
      auto_close!
      update_planning_application_for_auto_closed_request!
      update!(applicant_approved: true, auto_closed: true, auto_closed_at: Time.current)

      audit!(
        activity_type: "#{request_type}_#{self.class.name.underscore}_auto_closed",
        activity_information: sequence
      )
    end
  rescue ActiveRecord::ActiveRecordError, AASM::InvalidTransition => e
    Appsignal.send_error(e.message)
  end

  def reset_update_counter!
    return if post_validation?

    update!(update_counter: false)
  end

  def update_counter!
    unless replacement_document? ||
        red_line_boundary_change? ||
        other_change? ||
        fee_change?
      return
    end

    update!(update_counter: true)
  end

  def sent_by
    audits.find_by(activity_type: send_and_add_events, activity_information: sequence).try(:user)
  end

  def send_cancelled_validation_request_mail
    unless cancelled?
      raise ValidationRequest::CancelledEmailError,
        "Validation request: #{request_klass_name}, ID: #{id} must have a cancelled state."
    end

    PlanningApplicationMailer
      .cancelled_validation_request_mail(planning_application)
      .deliver_now
  end

  def replace_document!(file:, reason:)
    transaction do
      self.new_document = planning_application.documents.create!(
        file:,
        tags: old_document.tags,
        numbers: old_document.numbers
      )

      close!
      old_document.update!(archive_reason: reason, archived_at: Time.zone.now)
    end
  end

  private

  def send_and_add_events
    [
      "#{self.class.name.underscore}_sent_post_validation",
      "#{self.class.name.underscore}_sent",
      "#{self.class.name.underscore}_added"
    ]
  end

  def create_audit_for!(event)
    audit!(
      activity_type: "#{request_type}_#{self.class.name.underscore}_#{event}",
      activity_information: sequence.to_s
    )
  end

  def set_post_validation!
    update!(post_validation: true)
  end

  def email_and_timestamp
    if description_change?
      send_description_request_email

    else
      return unless planning_application.validation_complete?

      if post_validation?
        send_post_validation_request_email
      else
        send_validation_request_email
      end

    end
    mark_as_sent!
  end

  def send_validation_request_email
    PlanningApplicationMailer.validation_request_mail(
      planning_application
    ).deliver_now
  end

  def send_post_validation_request_email
    PlanningApplicationMailer.post_validation_request_mail(
      planning_application,
      self
    ).deliver_now
  end

  def send_description_request_email
    PlanningApplicationMailer.description_change_mail(
      planning_application,
      self
    ).deliver_now
  end

  def cancel_audit_event
    post_validation ? "cancelled_post_validation" : "cancelled"
  end

  def set_original_geojson
    self.original_geojson = planning_application.boundary_geojson
  end

  def red_line_boundary_change?
    request_type == "red_line_boundary_change"
  end

  def replacement_document?
    request_type == "replacement_document"
  end

  def description_change?
    request_type == "description_change"
  end

  def additional_document?
    request_type == "additional_document"
  end

  def other_change?
    request_type == "other"
  end

  def fee_change?
    request_type == "fee_change"
  end

  def document
    @document ||= documents.order(:created_at).last
  end

  def reset_columns
    reset_document_invalidation if replacement_document?
    reset_fee_invalidation if fee_change?
    reset_documents_missing if additional_document?
    reset_red_line_boundary_invalidation if red_line_boundary_change?
  end

  def reset_documents_missing
    return if planning_application.validation_requests.additional_documents.open_or_pending.excluding(self).any?

    planning_application.update!(documents_missing: nil)
  rescue ActiveRecord::ActiveRecordError => e
    raise ResetDocumentsMissingError, e.message
  end

  def reset_document_invalidation
    transaction do
      planning_application.validation_requests.replacement_documents.closed.find_by(new_document_id: old_document_id)&.update_counter!
      old_document.update!(invalidated_document_reason: nil, validated: nil)
    end
  rescue ActiveRecord::ActiveRecordError => e
    raise ResetDocumentInvalidationError, e.message
  end

  def reset_red_line_boundary_invalidation
    transaction do
      planning_application.validation_requests.red_line_boundary_changes.closed.max_by(&:closed_at)&.update_counter!
      planning_application.update!(valid_red_line_boundary: nil)
    end
  rescue ActiveRecord::ActiveRecordError => e
    raise ResetRedLineBoundaryInvalidationError, e.message
  end

  def set_previous_application_description
    self.previous_description = planning_application.description
  end

  def allows_only_one_open_description_change
    return unless planning_application.validation_requests.description_changes.open.any?

    errors.add(:base, "An open description change already exists for this planning application.")
  end

  def planning_application_has_not_been_determined
    return unless planning_application.determined?

    errors.add(:base, "A description change request cannot be submitted for a determined planning application.")
  end

  def update_planning_application_for_auto_closed_request!
    planning_application.update!(description: proposed_description)
  end

  def rejected_reason_is_present?
    return unless planning_application.invalidated?
    return if applicant_approved == false && applicant_rejection_reason.blank?

    errors.add(:base,
      "Please include a comment for the case officer to " \
      "indicate why the red line boundary change has been rejected.")
  end

  def ensure_no_open_or_pending_fee_item_validation_request
    return unless planning_application.validation_requests.fee_changes.open_or_pending.any?

    errors.add(:base, "An open or pending fee validation request already exists for this planning application.")
  end

  def set_invalid_payment_amount
    planning_application.update!(invalid_payment_amount: planning_application.payment_amount)
  end

  def reset_fee_invalidation
    transaction do
      planning_application.validation_requests.fee_changes.closed.max_by(&:closed_at)&.update_counter! if cancelled?
      planning_application.update!(valid_fee: nil)
    end
  rescue ActiveRecord::ActiveRecordError => e
    raise ResetFeeInvalidationError, e.message
  end

  def set_documents_missing
    return if planning_application.documents_missing?

    planning_application.update!(documents_missing: true)
  end

  def reset_documents_missing
    return if planning_application.validation_requests.additional_documents.open_or_pending.excluding(self).any?

    planning_application.update!(documents_missing: nil)
  rescue ActiveRecord::ActiveRecordError => e
    raise ResetDocumentsMissingError, e.message
  end

  def reset_replacement_document_validation_request_update_counter!
    request = ValidationRequest.find_by(new_document_id: old_document_id)

    request&.reset_update_counter!
  end
end
