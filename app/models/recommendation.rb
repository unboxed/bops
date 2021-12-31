# frozen_string_literal: true

class Recommendation < ApplicationRecord
  belongs_to :planning_application
  belongs_to :assessor, class_name: "User", optional: true
  belongs_to :reviewer, class_name: "User", optional: true

  scope :pending_review, -> { where(reviewer_id: nil) }
  scope :reviewed, -> { where.not(reviewer_id: nil) }
  scope :submitted, -> { where(submitted: true) }

  validate :reviewer_comment_is_present?

  attr_accessor :agree

  def current_recommendation?
    planning_application.recommendations.last == self
  end

  def reviewed?
    if current_recommendation? && planning_application.awaiting_determination?
      false
    else
      reviewer_comment.present?
    end
  end

  def reviewer_comment_is_present?
    if challenged? && !reviewer_comment?
      errors.add(:base,
                 "Please include a comment for the case officer to indicate why the recommendation has been challenged.")
    end
  end
end
