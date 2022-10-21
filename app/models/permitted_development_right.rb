# frozen_string_literal: true

class PermittedDevelopmentRight < ApplicationRecord
  belongs_to :planning_application

  enum status: {
    in_progress: "in_progress",
    checked: "checked",
    removed: "removed"
  }

  with_options presence: true do
    validates :status
    validates :removed_reason, if: :removed
  end

  before_update :reset_removed_reason, if: :removed_changed?

  private

  def reset_removed_reason
    return unless removed_was && removed_reason

    update!(removed_reason: nil)
  end
end
