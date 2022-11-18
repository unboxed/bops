# frozen_string_literal: true

class PermittedDevelopmentRight < ApplicationRecord
  belongs_to :planning_application

  with_options class_name: "User", optional: true do
    belongs_to :assessor
    belongs_to :reviewer
  end

  with_options presence: true do
    validates :status, :review_status
    validates :removed_reason, if: :removed
  end

  enum status: {
    in_progress: "in_progress",
    checked: "checked",
    removed: "removed",
    to_be_reviewed: "to_be_reviewed"
  }

  enum review_status: {
    review_not_started: "review_not_started",
    review_in_progress: "review_in_progress",
    review_complete: "review_complete"
  }
end
