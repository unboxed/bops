# frozen_string_literal: true

class ConditionSet < ApplicationRecord
  include Reviewable

  belongs_to :planning_application
  has_many :conditions, extend: ConditionsExtension

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
end
