# frozen_string_literal: true

require "aasm"

module EnforcementStatus
  extend ActiveSupport::Concern

  included do
    include AASM

    enum :status, {
      not_started: "not_started",
      under_investigation: "under_investigation",
      closed: "closed"
    }

    aasm column: :status, enum: true, whiny_persistence: true, no_direct_assignment: true, timestamps: true do
      state :not_started, initial: true
      state :under_investigation
      state :closed

      event :start_investigation do
        transitions from: :not_started, to: :under_investigation
      end

      event :close do
        transitions from: [:not_started, :under_investigation], to: :closed
      end
    end
  end
end
