# frozen_string_literal: true

class ConditionSet < ApplicationRecord
  include Reviewable

  belongs_to :planning_application
  has_many :conditions, extend: ConditionsExtension

  before_save :set_review_updated

  accepts_nested_attributes_for :conditions, allow_destroy: true

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

  def set_review_updated
    review.updated! if complete? && review.to_be_reviewed?
  end
end
