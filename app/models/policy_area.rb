# frozen_string_literal: true

class PolicyArea < ApplicationRecord
  belongs_to :planning_application

  has_many :considerations, dependent: :destroy
  has_many :review_policy_areas, dependent: :destroy

  after_create :create_review_policy_area
  before_update :maybe_create_review_policy_area

  AREAS = %w[design impact_on_neighbours other].freeze

  accepts_nested_attributes_for :considerations
  validates_associated :considerations
  validates :considerations, presence: { if: :completed? }

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

  def current_review_policy_area
    review_policy_areas.where.not(id: nil).order(:created_at).last
  end

  private

  def maybe_create_review_policy_area
    return unless status_changed? && status_change == %w[to_be_reviewed complete]

    create_review_policy_area
  end

  def create_review_policy_area
    ReviewPolicyArea.create!(assessor: Current.user, policy_area: self)
  end

  def completed?
    status == "complete"
  end
end
