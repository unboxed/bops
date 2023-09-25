# frozen_string_literal: true

class PolicyGuidance < ApplicationRecord
  belongs_to :planning_application

  validates :assessment, :policies, presence: { if: :completed? }

  has_many :review_policy_guidances, dependent: :destroy

  after_create :create_review_policy_guidance
  before_update :maybe_create_review_policy_guidance

  enum(
    status: {
      not_started: "not_started",
      in_progress: "in_progress",
      to_be_reviewed: "to_be_reviewed",
      complete: "complete"
    },
    _default: "not_started"
  )

  enum review_status: {
    review_not_started: "review_not_started",
    review_in_progress: "review_in_progress",
    review_complete: "review_complete"
  }

  with_options presence: true do
    validates :status, :review_status
  end

  def current_review_policy_guidance
    review_policy_guidances.where.not(id: nil).order(:created_at).last
  end

  def maybe_create_review_policy_guidance
    return unless status_changed? && status_change == %w[to_be_reviewed complete]

    create_review_policy_guidance
  end

  def create_review_policy_guidance
    ReviewPolicyGuidance.create!(assessor: Current.user, policy_guidance: self)
  end

  private

  def completed?
    status == "complete"
  end
end
