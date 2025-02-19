# frozen_string_literal: true

require "aasm"

module PlanningApplicationStatus
  extend ActiveSupport::Concern

  include Auditable

  IN_PROGRESS_STATUSES = %i[not_started in_assessment invalidated awaiting_determination in_committee to_be_reviewed].freeze
  PRIVATE_STATUSES = %i[invalidated not_started returned pending].freeze

  included do
    include AASM

    scope :not_started_and_invalid, lambda {
      where(status: %w[not_started invalidated])
    }

    scope :under_assessment, lambda {
      where(status: %w[in_assessment assessment_in_progress to_be_reviewed])
    }

    scope :closed, lambda {
      where(status: %w[determined withdrawn returned closed])
    }

    scope :publishable, lambda {
      where.not(status: PRIVATE_STATUSES)
    }

    aasm.attribute_name :status

    aasm whiny_persistence: true, no_direct_assignment: true do
      state :pending, initial: true
      state :not_started
      state :invalidated, display: "invalid"
      state :assessment_in_progress
      state :in_assessment
      state :awaiting_determination
      state :in_committee
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
          request_names = validation_requests.open.map(&:audit_name).join(", ")
          audit!(activity_type: "validation_requests_sent", activity_information: request_names)
          audit!(activity_type: "invalidated")
        end
      end

      event :send_to_committee do
        transitions from: :awaiting_determination, to: :in_committee do
          guard do
            committee_decision&.recommend?
          end
        end

        after do
          audit!(
            activity_type: "sent_to_committee",
            audit_comment: "Application was sent to committee"
          )
        end
      end

      event :determine do
        transitions from: %i[awaiting_determination in_committee], to: :determined

        after do
          audit!(
            activity_type: "determined",
            audit_comment: "Application #{decision} on #{determination_date.to_date.to_fs} (manually inputted date)"
          )
        end
      end

      event :request_correction do
        transitions from: %i[awaiting_determination in_committee], to: :to_be_reviewed,
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
        transitions from: %i[in_assessment in_committee], to: :awaiting_determination,
          guards: %i[decision_present? no_open_post_validation_requests_excluding_time_extension?] do
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

    def recommendable?
      true unless closed_or_cancelled? || invalidated? || not_started?
    end

    def in_progress?
      true unless closed_or_cancelled?
    end

    def validated?
      true unless not_started? || invalidated?
    end

    def can_validate?
      true unless awaiting_determination? || closed_or_cancelled?
    end

    def validation_complete?
      !not_started?
    end

    def can_assess?
      assessment_in_progress? || in_assessment? || to_be_reviewed?
    end

    def closed_or_cancelled?
      determined? || returned? || withdrawn? || closed?
    end

    def can_submit_recommendation?
      assessment_complete? && (in_assessment? || to_be_reviewed?)
    end

    def submit_recommendation_complete?
      awaiting_determination? || determined?
    end

    def publish_complete?
      determined?
    end

    def officer_can_draw_boundary?
      not_started? || invalidated?
    end

    def can_edit_documents?
      can_validate? || publish_complete?
    end

    def review_complete?
      to_be_reviewed? || determined?
    end

    def reviewer_disagrees_with_assessor?
      to_be_reviewed?
    end
  end
end
