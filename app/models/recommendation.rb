# frozen_string_literal: true

class Recommendation < ApplicationRecord
  class ReviewRecommendationError < StandardError; end

  include Auditable

  belongs_to :planning_application
  belongs_to :assessor, class_name: "User", optional: true
  belongs_to :reviewer, class_name: "User", optional: true

  scope :pending_review, -> { where(reviewer_id: nil) }
  scope :reviewed, -> { where.not(reviewer_id: nil) }
  scope :submitted, -> { where(submitted: true) }

  with_options if: :review_complete? do
    validate :reviewer_comment_is_present?
    validate :no_updates_required
  end

  delegate :audits, to: :planning_application

  enum(
    status: {
      assessment_in_progress: 0,
      assessment_complete: 1,
      review_in_progress: 2,
      review_complete: 3
    }
  )

  def current_recommendation?
    planning_application.recommendation == self
  end

  def reviewed?
    if current_recommendation? && planning_application.awaiting_determination?
      false
    else
      reviewer.present?
    end
  end

  def review!
    transaction do
      update!(reviewed_at: Time.current, reviewer: Current.user)

      if challenged?
        planning_application.request_correction!(reviewer_comment) unless committee_overturned?
      elsif planning_application.committee_decision&.recommend? && planning_application.awaiting_determination?
        planning_application.send_to_committee!
      else
        planning_application.submit! if planning_application.in_committee?
        audit!(activity_type: "approved", audit_comment: reviewer_comment)
      end
    end
  rescue ActiveRecord::ActiveRecordError, AASM::InvalidTransition => e
    raise ReviewRecommendationError, e.message
  end

  def submitted_and_unchallenged?
    submitted? && unchallenged?
  end

  def unchallenged?
    !challenged
  end

  def accepted?
    review_complete? && challenged == false
  end

  def rejected?
    review_complete? && challenged?
  end

  private

  def no_updates_required
    return unless unchallenged? && planning_application.updates_required?

    errors.add(:challenged, :updates_required)
  end

  def reviewer_comment_is_present?
    return unless challenged? && !reviewer_comment? && !committee_overturned?

    errors.add(:base,
      "Explain to the case officer why the recommendation has been challenged.")
  end
end
