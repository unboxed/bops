# frozen_string_literal: true

class ConditionSet < ApplicationRecord
  belongs_to :planning_application
  has_one :review, as: :owner, dependent: :destroy, class_name: "Review"
  has_many :conditions, extend: ConditionsExtension, dependent: :destroy

  before_save :set_review_updated

  accepts_nested_attributes_for :conditions, allow_destroy: true
  accepts_nested_attributes_for :review, update_only: true

  enum :status, {
    not_started: "not_started",
    in_progress: "in_progress",
    to_be_reviewed: "to_be_reviewed",
    complete: "complete"
  }, default: "not_started"

  def review
    super || create_review!
  end

  private

  def create_review!
    Review.create!(assessor: Current.user, owner_type: "ConditionSet", owner_id: self.id)
  end

  def set_review_updated
    review.updated! if complete? && review.to_be_reviewed?
  end
end
