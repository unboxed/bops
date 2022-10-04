# frozen_string_literal: true

class AssessmentDetail < ApplicationRecord
  belongs_to :planning_application
  belongs_to :user

  enum status: {
    in_progress: "in_progress",
    completed: "completed"
  }

  enum category: {
    summary_of_work: "summary_of_work",
    additional_evidence: "additional_evidence"
  }

  validates :status, presence: true
  validates :entry, presence: true, if: :summary_of_work?

  scope :by_created_at_desc, -> { order(created_at: :desc) }

  categories.each do |category|
    scope :"#{category}", -> { where(category: category) }
  end
end
