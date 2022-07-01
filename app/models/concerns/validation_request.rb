# frozen_string_literal: true

module ValidationRequest
  extend ActiveSupport::Concern

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

  included do
    before_create :set_sequence
    before_create :ensure_planning_application_not_closed_or_cancelled!

    before_destroy :ensure_validation_request_destroyable!
    after_create :set_post_validation!, if: :planning_application_validated?
    after_create :email_and_timestamp, if: :pending?
    after_create :create_audit!

    validates :cancel_reason, presence: true, if: :cancelled?

    scope :not_cancelled, -> { where(cancelled_at: nil) }
    scope :open_or_pending, -> { open.or(pending) }
    scope :post_validation, -> { where(post_validation: true) }

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
          update!(cancelled_at: Time.current)
        end
      end

      event :auto_approve do
        transitions from: :open, to: :closed

        after do
          planning_application.update!(description: proposed_description)
          update!(approved: true, auto_closed: true)
          audit!(activity_type: "auto_closed")
        end
      end

      event :close do
        transitions from: :open, to: :closed
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
      self.sequence = self.class.where(planning_application: planning_application).count + 1
    end
  end

  def audit_name
    "#{model_name.human} ##{sequence}"
  end

  def cancel_request!
    transaction do
      cancel!
      reset_columns
      audit!(activity_type: "#{self.class.name.underscore}_#{cancel_audit_event}", activity_information: sequence,
             audit_comment: { cancel_reason: cancel_reason }.to_json)
    end
  rescue ActiveRecord::ActiveRecordError, AASM::InvalidTransition => e
    raise RecordCancelError, e.message
  end

  def can_cancel?
    may_cancel? && planning_application.invalidated?
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

  def open_or_pending?
    open? || pending?
  end

  def active_closed_fee_item?
    try(:fee_item?) && closed? && self == planning_application.fee_item_validation_requests.not_cancelled.last
  end

  def request_expiry_date
    5.business_days.after(created_at)
  end

  private

  def create_audit_for!(event)
    audit!(
      activity_type: "#{self.class.name.underscore}_#{event}",
      activity_information: sequence.to_s,
      audit_comment: audit_comment
    )
  end

  def reset_columns
    reset_document_invalidation if is_a?(ReplacementDocumentValidationRequest)
    reset_fee_invalidation if is_a?(OtherChangeValidationRequest) && fee_item?
    reset_documents_missing if is_a?(AdditionalDocumentValidationRequest)
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
end
