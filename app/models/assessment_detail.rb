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
    additional_evidence: "additional_evidence",
    site_description: "site_description",
    past_applications: "past_applications",
    consultation_summary: "consultation_summary"
  }

  validates :status, presence: true
  validates :entry, presence: true, if: :validate_entry_presence?

  validate :consultees_added, if: :consultation_summary?

  scope :by_created_at_desc, -> { order(created_at: :desc) }

  delegate :consultees, to: :planning_application

  categories.each do |category|
    scope :"#{category}", -> { where(category: category) }
  end

  private

  def validate_entry_presence?
    summary_of_work? ||
      site_description? ||
      (completed? && (past_applications? || consultation_summary?))
  end

  def consultees_added
    errors.add(:base, :no_consultees_added) if completed? && consultees.none?
  end
end
