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

  validate :reviewer_comment_is_present?, if: :review_complete?

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
        planning_application.request_correction!(reviewer_comment)
      else
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

  def reviewer_comment_is_present?
    if challenged? && !reviewer_comment?
      errors.add(:base,
                 "Please include a comment for the case officer to indicate why the recommendation has been challenged.")
    end
  end
end
