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

  with_options class_name: "User", optional: true do
    belongs_to :assessor
    belongs_to :reviewer
  end

  with_options presence: true do
    validates :status, :review_status
  end

  def update_required?
    complete? && !accepted
  end
end
