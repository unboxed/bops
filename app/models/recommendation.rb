class Recommendation < ApplicationRecord
  belongs_to :planning_application
  belongs_to :assessor, class_name: "User"
  belongs_to :reviewer, class_name: "User", optional: true

  validate :reviewer_comment_is_present?

  scope :pending_review, -> { where(reviewer_id: nil) }
  scope :reviewed, -> { where("reviewer_id IS NOT NULL") }

  attr_accessor :agree

  def current_recommendation?
    planning_application.recommendations.last == self
  end

  def reviewed?
    if current_recommendation? && planning_application.awaiting_determination?
      false
    else
      reviewer.present?
    end
  end

  def reviewer_comment_is_present?
    if challenged?
      errors.add(:base, "When challenging a recommendation, a reviewer comment is required.")
    end
  end
end
