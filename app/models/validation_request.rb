# frozen_string_literal: true

class ValidationRequest < ApplicationRecord
  RESPONSE_TIME_IN_DAYS = 15

  REQUEST_TYPES = %w[
    AdditionalDocumentValidationRequest
    DescriptionChangeValidationRequest
    RedLineBoundaryChangeValidationRequest
    ReplacementDocumentValidationRequest
    OwnershipCertificateValidationRequest
    OtherChangeValidationRequest
    FeeChangeValidationRequest
    PreCommencementConditionValidationRequest
  ].freeze

  with_options to: :planning_application do
    delegate :audits
    delegate :validated?, prefix: :planning_application
    delegate :closed_or_cancelled?, prefix: :planning_application
    delegate :reset_validation_requests_update_counter!
  end

  include Auditable

  class RecordCancelError < RuntimeError; end

  class NotDestroyableError < StandardError; end

  class CancelledEmailError < StandardError; end

  class ValidationRequestNotCreatableError < StandardError; end

  class UploadFilesError < RuntimeError; end

  class ResetDocumentInvalidationError < StandardError; end

  belongs_to :planning_application
  belongs_to :user
  belongs_to :old_document, class_name: "Document", optional: true

  validates :type, presence: true, inclusion: {in: REQUEST_TYPES}

  scope :closed, -> { where(state: "closed") }
  scope :active, -> { where.not(state: "cancelled") }
  scope :cancelled, -> { where(state: "cancelled") }
  scope :pending, -> { where(state: "pending") }
  scope :not_cancelled, -> { where(cancelled_at: nil) }
  scope :open_or_pending, -> { open.or(pending) }
  scope :post_validation, -> { where(post_validation: true) }
  scope :open_change_created_over_5_business_days_ago, -> { open.where("created_at <= ?", 5.business_days.ago) }
  scope :open_change_created_over_10_business_days_ago, -> { open.where("created_at <= ?", 10.business_days.ago) }
  scope :pre_validation, -> { where(post_validation: false) }
  scope :responded, -> { where.not(response: nil).or(where(approved: true)) }
  scope :with_active_document, -> { joins(:old_document).where(documents: {archived_at: nil}) }

  store_accessor :specific_attributes, %w[new_geojson original_geojson suggestion document_request_type proposed_description previous_description]

  before_create :set_sequence
  before_create :ensure_planning_application_not_closed_or_cancelled!
  after_create :set_post_validation!, if: :planning_application_validated?
  after_create :email_and_timestamp, if: :pending?
  after_create :create_audit!
  before_destroy :ensure_validation_request_destroyable!
  after_destroy :reset_columns

  REQUEST_TYPES.each do |type|
    scope "#{type.underscore[/^.*(?=(_validation_request))/]}s", -> { where(type: type) }
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
    RESPONSE_TIME_IN_DAYS.business_days.after(created_at.to_date)
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

  def cancel_request!
    transaction do
      cancel!
      reset_columns
      audit!(
        activity_type: "#{type.underscore}_#{cancel_audit_event}",
        activity_information: sequence,
        audit_comment: {cancel_reason:}.to_json
      )
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
      activity_type: "#{type.underscore}_received",
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

  def open_or_pending?
    open? || pending?
  end

  def active_closed_fee_item?
    fee_change? && closed? && self == planning_application.fee_change_validation_requests.closed.last
  end

  def request_expiry_date
    5.business_days.after(created_at)
  end

  def auto_close_request!
    transaction do
      auto_close!
      update_planning_application_for_auto_closed_request!
      update!(approved: true, auto_closed: true, auto_closed_at: Time.current)

      audit!(
        activity_type: "#{type.underscore}_auto_closed",
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

  def rejected?
    !approved && rejection_reason.present?
  end

  def update_planning_application!(params)
    # Specific types of validation request use this method, which is overwritten in those models.
    #  A couple don't hence the empty method
  end

  private

  def send_and_add_events
    [
      "#{type.underscore}_sent_post_validation",
      "#{type.underscore}_sent",
      "#{type.underscore}_added"
    ]
  end

  def create_audit_for!(event)
    audit!(
      activity_type: "#{type.underscore}_#{event}",
      activity_information: sequence.to_s,
      audit_comment:
    )
  end

  def audit_upload_files!
    audit!(
      activity_type: "additional_document_validation_request_received",
      activity_information: sequence,
      audit_comment: additional_documents.map(&:name).join(", ")
    )
  end

  def set_post_validation!
    update!(post_validation: true)
  end

  def email_and_timestamp
    return unless planning_application.validation_complete?

    if post_validation?
      send_post_validation_request_email
    else
      send_validation_request_email
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

  def red_line_boundary_change?
    type == "RedLineBoundaryChangeValidationRequest"
  end

  def replacement_document?
    type == "ReplacementDocumentValidationRequest"
  end

  def description_change?
    type == "DescriptionChangeValidationRequest"
  end

  def additional_document?
    type == "AdditionalDocumentValidationRequest"
  end

  def other_change?
    type == "OtherChangeValidationRequest"
  end

  def fee_change?
    type == "FeeChangeValidationRequest"
  end

  def reset_columns
    reset_document_invalidation if replacement_document?
    reset_fee_invalidation if fee_change?
    reset_documents_missing if additional_document?
    reset_red_line_boundary_invalidation if red_line_boundary_change?
  end

  def reset_red_line_boundary_invalidation
    transaction do
      planning_application.red_line_boundary_change_validation_requests.closed.max_by(&:closed_at)&.update_counter!
      planning_application.update!(valid_red_line_boundary: nil)
    end
  rescue ActiveRecord::ActiveRecordError => e
    raise ResetRedLineBoundaryInvalidationError, e.message
  end

  def reset_documents_missing
    return if planning_application.additional_document_validation_requests.open_or_pending.excluding(self).any?

    planning_application.update!(documents_missing: nil)
  rescue ActiveRecord::ActiveRecordError => e
    raise ResetDocumentsMissingError, e.message
  end

  def ensure_planning_application_not_closed_or_cancelled!
    return unless planning_application_closed_or_cancelled?

    raise ValidationRequestNotCreatableError,
      "Cannot create #{type.titleize} when planning application has been closed or cancelled"
  end
end
