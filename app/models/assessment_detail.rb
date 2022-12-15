# frozen_string_literal: true

class AssessmentDetail < ApplicationRecord
  belongs_to :planning_application
  belongs_to :user
  has_one :comment, as: :commentable, dependent: :destroy

  enum(
    assessment_status: {
      not_started: "not_started",
      in_progress: "in_progress",
      complete: "complete"
    },
    _default: "not_started",
    _prefix: "assessment"
  )

  enum(
    review_status: {
      in_progress: "in_progress",
      complete: "complete"
    },
    _prefix: "review"
  )

  enum reviewer_verdict: {
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

  validates :assessment_status, presence: true
  validates :entry, presence: true, if: :validate_entry_presence?

  validates(
    :additional_information,
    presence: true,
    if: :validate_additional_information_presence?
  )

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

  def review_required?
    assessment_complete? && reviewer_verdict.blank?
  end

  private

  def validate_additional_information_presence?
    past_applications? && assessment_complete?
  end

  def validate_entry_presence?
    return false if accepted? || rejected?

    summary_of_work? ||
      site_description? ||
      (assessment_complete? && consultation_summary?)
  end

  def set_user
    self.user = user || Current.user
  end
end
