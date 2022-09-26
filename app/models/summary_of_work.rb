# frozen_string_literal: true

class SummaryOfWork < ApplicationRecord
  belongs_to :planning_application
  belongs_to :user

  validates :entry, :status, presence: true

  scope :by_created_at_desc, -> { order(created_at: :desc) }

  enum status: {
    in_progress: "in_progress",
    completed: "completed"
  }
end
