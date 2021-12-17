# frozen_string_literal: true

module ValidationRequest
  extend ActiveSupport::Concern
  include AuditableModel

  class RecordCancelError < RuntimeError; end

  class NotDestroyableError < StandardError; end

  class CancelledEmailError < StandardError; end

  included do
    before_create :set_sequence

    before_destroy :ensure_validation_request_destroyable!

    validates :cancel_reason, presence: true, if: :cancelled?

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
          audit_auto_closed!
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
      audit_cancel_request!
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

  def audit!
    if is_a?(DescriptionChangeValidationRequest)
      audit_request_sent_or_added(self, "sent")
    else
      event = planning_application.invalidated? ? "sent" : "added"
      audit_request_sent_or_added(self, event)
    end
  end

  private

  def audit_request_sent_or_added(request, event)
    audit("#{request.model_name.param_key}_#{event}",
          request.audit_item.to_s,
          request.sequence.to_s)
  end

  def audit_cancel_request!
    Audit.create!(
      planning_application_id: planning_application.id,
      user: Current.user,
      audit_comment: { cancel_reason: cancel_reason }.to_json,
      activity_information: sequence,
      activity_type: "#{self.class.name.underscore}_cancelled"
    )
  end

  def audit_auto_closed!
    Audit.create!(
      planning_application_id: planning_application.id,
      user: Current.user,
      activity_type: "auto_closed"
    )
  end
end
