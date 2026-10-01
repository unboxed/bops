# frozen_string_literal: true

require "aasm"

module EnforcementStatus
  extend ActiveSupport::Concern

  included do
    include AASM

    enum :status, %i[
      not_started
      in_validation
      under_investigation
      in_review
      notice_served
      notice_overdue
      notice_withdrawn
      appeal
      prosecution
      closed
    ].index_by(&:to_sym)

    aasm column: :status, enum: true, whiny_persistence: true, no_direct_assignment: true, timestamps: true do
      state :not_started, initial: true
      state :in_validation
      state :under_investigation
      state :in_review
      state :notice_served
      state :notice_overdue
      state :notice_withdrawn
      state :appeal
      state :prosecution
      state :closed

      event :start_validation do
        transitions from: :not_started, to: :in_validation
        transitions from: Enforcement.statuses.keys
        after { audit!(activity_type: "started") }
      end

      event :start_investigation do
        transitions from: %i[not_started in_validation], to: :under_investigation
        after { audit!(activity_type: "validation_complete") }
      end

      event :mark_for_review do
        transitions from: :under_investigation, to: :in_review
        after { audit!(activity_type: "investigation_complete") }
      end

      event :close do
        transitions from: %i[not_started in_validation under_investigation in_review], to: :closed
        after { audit!(activity_type: "closed") }
      end
    end
  end
end
