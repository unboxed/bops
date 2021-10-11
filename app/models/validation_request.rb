# frozen_string_literal: true

module ValidationRequest
  extend ActiveSupport::Concern

  included do
    include AASM

    aasm.attribute_name :state

    aasm do
      state :pending, initial: true
      state :open
      state :closed

      event :mark_as_sent! do
        transitions from: :pending, to: :open

        after do
          update!(notified_at: Time.zone.now)
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
      self.sequence = self.class.where(planning_application: planning_application).count + 1
    end
  end

  def audit_name
    "#{model_name.human} ##{sequence}"
  end
end
