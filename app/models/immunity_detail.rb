# frozen_string_literal: true

class ImmunityDetail < ApplicationRecord
  belongs_to :planning_application

  enum(
    status: {
      not_started: "not_started",
      in_progress: "in_progress",
      complete: "complete"
    },
    _default: "not_started"
  )

  enum review_status: {
    review_not_started: "review_not_started",
    review_in_progress: "review_in_progress",
    review_complete: "review_complete"
  }

  validates :status, presence: true

  def update_required?
    complete? && !accepted
  end
end
