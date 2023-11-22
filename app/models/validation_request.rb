# frozen_string_literal: true

class ValidationRequest < ApplicationRecord
  VALIDATION_REQUEST_TYPES = %w[
    additional_document
    description_change
    red_line_boundary_change
    replacement_document
    fee_change
    other
  ].freeze

  with_options to: :planning_application do
    delegate :audits
    delegate :validated?, prefix: :planning_application
    delegate :closed_or_cancelled?, prefix: :planning_application
  end

  include Auditable

  class RecordCancelError < RuntimeError; end

  class NotDestroyableError < StandardError; end

  class CancelledEmailError < StandardError; end

  class ValidationRequestNotCreatableError < StandardError; end

  belongs_to :requestable, polymorphic: true, optional: true
  belongs_to :planning_application
  belongs_to :user
  belongs_to :old_document, optional: true, class_name: "Document"
  belongs_to :new_document, optional: true, class_name: "Document"

  validates :request_type, presence: true, inclusion: {in: VALIDATION_REQUEST_TYPES}
  validates :reason, presence: true
  validates :suggestion, presence: true, if: :fee_change?

  scope :closed, -> { where.not(closed_at: nil) }
  scope :active, -> { where.not(state: "cancelled") }
  scope :cancelled, -> { where(state: "cancelled") }
  scope :not_cancelled, -> { where(cancelled_at: nil) }
  scope :open_or_pending, -> { open.or(pending) }
  scope :post_validation, -> { where(post_validation: true) }
  scope :open_change_created_over_5_business_days_ago, -> { open.where("created_at <= ?", 5.business_days.ago) }
  scope :pre_validation, -> { where(post_validation: false) }
  scope :overdue, -> { where(state: ["open", "overdue"]) }
  scope :responsed, -> { where.not(responded_at: nil) }

  store_accessor :specific_attributes, %w[new_geojson original_geojson suggestion document_request_type proposed_description previous_description]

  before_create :set_original_geojson, if: :red_line_boundary_change?
  after_destroy :reset_columns

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
        validation_request.update!(closed_at: Time.current)
      end
    end
  end

  def response_due
    15.business_days.after(created_at.to_date)
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

  def create_validation_request!
    ValidationRequest.create!(requestable_id: id, requestable_type: self.class,
      planning_application:)
  end

  def open_or_pending?
    open? || pending?
  end

  def active_closed_fee_item?
    try(:fee_item?) && closed? && self == planning_application.fee_item_validation_requests.not_cancelled.last
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
        activity_type: "#{self.class.name.underscore}_auto_closed",
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
    unless is_a?(ReplacementDocumentValidationRequest) ||
        is_a?(RedLineBoundaryChangeValidationRequest) ||
        is_a?(OtherChangeValidationRequest)
      return
    end

    validation_request.update!(update_counter: true)
  end

  def sent_by
    audits.find_by(activity_type: send_and_add_events, activity_information: sequence).try(:user)
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
      activity_type: "#{self.class.name.underscore}_#{event}",
      activity_information: sequence.to_s,
      audit_comment:
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

  def set_original_geojson
    self.original_geojson = planning_application.boundary_geojson
  end

  def red_line_boundary_change?
    request_type == "red_line_boundary_change"
  end

  def fee_change?
    request_type == "fee_change"
  end

  def send_cancelled_validation_request_mail
    unless cancelled?
      raise ValidationRequest::CancelledEmailError,
        "Validation request: #{request_klass_name}, ID: #{id} must have a cancelled state."
    end

    PlanningApplicationMailer
      .cancelled_validation_request_mail(@planning_application)
      .deliver_now
  end

  def reset_columns
    reset_document_invalidation if request_type == "replacement_document"
    reset_fee_invalidation if fee_change?
    reset_documents_missing if request_type == "addtional_document"
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
      replacement_documents.closed.find_by(new_document_id: old_document_id)&.update_counter!
      old_document.update!(invalidated_document_reason: nil, validated: nil)
    end
  rescue ActiveRecord::ActiveRecordError => e
    raise ResetDocumentInvalidationError, e.message
  end

  def reset_fee_invalidation
    transaction do
      planning_application.validation_requests.fee_changes.closed.max_by(&:closed_at)&.update_counter! if cancelled?
      planning_application.update!(valid_fee: nil)
    end
  rescue ActiveRecord::ActiveRecordError => e
    raise ResetFeeInvalidationError, e.message
  end

  def reset_red_line_boundary_invalidation
    transaction do
      planning_application.validation_requests.red_line_boundary_changes.closed.max_by(&:closed_at)&.update_counter!
      planning_application.update!(valid_red_line_boundary: nil)
    end
  rescue ActiveRecord::ActiveRecordError => e
    raise ResetRedLineBoundaryInvalidationError, e.message
  end
end
