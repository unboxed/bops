# frozen_string_literal: true

require "aasm"

module PlanningApplicationStatus
  extend ActiveSupport::Concern

  include Auditable

  IN_PROGRESS_STATUSES = %i[not_started in_assessment invalidated awaiting_determination to_be_reviewed].freeze

  included do
    include AASM

    scope :not_started_and_invalid, lambda {
      where("status = 'not_started' OR status = 'invalidated'")
    }
    scope :under_assessment, lambda {
      where("status = 'in_assessment' OR status = 'assessment_in_progress' OR status = 'to_be_reviewed'")
    }
    scope :closed, lambda {
      where("status = 'determined' OR status = 'withdrawn' OR status = 'returned' OR status = 'closed'")
    }

    aasm.attribute_name :status

    aasm whiny_persistence: true, no_direct_assignment: true do
      state :pending, initial: true
      state :not_started
      state :invalidated, display: "invalid"
      state :assessment_in_progress
      state :in_assessment
      state :awaiting_determination
      state :to_be_reviewed
      state :determined
      state :returned
      state :withdrawn
      state :closed

      event :mark_accepted do
        transitions from: :pending, to: :not_started
      end

      event :start do
        transitions from: %i[not_started invalidated in_assessment], to: :in_assessment, guard: :validation_date?

        after { audit!(activity_type: "started") }
      end

      event :save_assessment do
        transitions from: %i[in_assessment assessment_in_progress], to: :assessment_in_progress

        after do
          save(validate: false)
        end
      end

      event :assess do
        transitions from: %i[in_assessment assessment_in_progress to_be_reviewed], to: :in_assessment,
          guard: :decision_present?
      end

      event :invalidate do
        transitions from: :not_started, to: :invalidated, guard: :pending_validation_requests? do
          after { pending_validation_requests.each(&:mark_as_sent!) }
        end

        after do
          request_names = open_validation_requests.map(&:audit_name).join(", ")
          audit!(activity_type: "validation_requests_sent", activity_information: request_names)
          audit!(activity_type: "invalidated")
        end
      end

      event :determine do
        transitions from: :awaiting_determination, to: :determined

        after do
          audit!(
            activity_type: "determined",
            audit_comment: "Application #{decision} on #{determination_date.to_date.to_fs} (manually inputted date)"
          )
        end
      end

      event :request_correction do
        transitions from: :awaiting_determination, to: :to_be_reviewed,
          after: proc { |comment| audit!(activity_type: "challenged", audit_comment: comment) }

        after { send_update_notification_to_assessor }
      end

      event :return do
        transitions from: IN_PROGRESS_STATUSES, to: :returned,
          after: proc { |comment| update!(closed_or_cancellation_comment: comment) }

        after { audit!(activity_type: "returned", audit_comment: closed_or_cancellation_comment) }
      end

      event :withdraw do
        transitions from: IN_PROGRESS_STATUSES, to: :withdrawn,
          after: proc { |comment| update!(closed_or_cancellation_comment: comment) }

        after { audit!(activity_type: "withdrawn", audit_comment: closed_or_cancellation_comment) }
      end

      event :close do
        transitions from: IN_PROGRESS_STATUSES, to: :closed,
          after: proc { |comment| update!(closed_or_cancellation_comment: comment) }

        after { audit!(activity_type: "closed", audit_comment: closed_or_cancellation_comment) }
      end

      event :submit do
        transitions from: :in_assessment, to: :awaiting_determination,
          guards: %i[decision_present? no_open_post_validation_requests?] do
          after { recommendation.update!(submitted: true) }
        end
      end

      event :withdraw_recommendation do
        transitions from: :awaiting_determination, to: :in_assessment do
          after { recommendation.update!(submitted: false) }
        end
      end

      after_all_transitions :timestamp_status_change # FIXME: https://github.com/aasm/aasm#timestamps
    end
  end
end
