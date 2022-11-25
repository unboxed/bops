# frozen_string_literal: true

class AssessmentDetail < ApplicationRecord
  belongs_to :planning_application
  belongs_to :user
  has_one :comment, as: :commentable, dependent: :destroy

  enum status: {
    assessment_in_progress: "assessment_in_progress",
    assessment_complete: "assessment_complete",
    review_in_progress: "review_in_progress",
    review_complete: "review_complete"
  }

  enum review_status: {
    updated: "updated",
    accepted: "accepted",
    edited_and_accepted: "edited_and_accepted",
    rejected: "rejected"
  }

  enum category: {
    summary_of_work: "summary_of_work",
    additional_evidence: "additional_evidence",
    site_description: "site_description",
    past_applications: "past_applications",
    consultation_summary: "consultation_summary"
  }

  before_validation :set_user

  validates :status, presence: true
  validates :entry, presence: true, if: :validate_entry_presence?

  validate :consultees_added, if: :consultation_summary?

  scope :by_created_at_desc, -> { order(created_at: :desc) }

  delegate :consultees, to: :planning_application

  categories.each do |category|
    scope :"#{category}", -> { where(category: category) }
  end

  def existing_or_new_comment
    comment || build_comment
  end

  def update_required?
    review_complete? && rejected?
  end

  private

  def validate_entry_presence?
    return false if accepted? || rejected?

    summary_of_work? ||
      site_description? ||
      (assessment_complete? && (past_applications? || consultation_summary?))
  end

  def consultees_added
    return if !assessment_complete? || consultees.any?

    errors.add(:base, :no_consultees_added)
  end

  def set_user
    self.user = user || Current.user
  end
end
