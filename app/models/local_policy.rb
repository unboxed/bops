# frozen_string_literal: true

class LocalPolicy < ApplicationRecord
  belongs_to :planning_application

  has_many :local_policy_areas, dependent: :destroy
  has_many :review_local_policies, dependent: :destroy

  after_create :create_review_local_policy
  before_update :maybe_create_review_local_policy

  AREAS = %w[design impact_on_neighbours other].freeze

  accepts_nested_attributes_for :local_policy_areas
  validates_associated :local_policy_areas
  validates :local_policy_areas, presence: {if: :completed?}

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

  def current_review_local_policy
    review_local_policies.where.not(id: nil).order(:created_at).last
  end

  def review_local_polices_with_comments
    review_local_policies.where.not("reviewer_comment = '' OR reviewer_comment IS NULL").order(:created_at)
  end

  private

  def maybe_create_review_local_policy
    return unless status_changed? && status_change == %w[to_be_reviewed complete]

    create_review_local_policy
  end

  def create_review_local_policy
    ReviewLocalPolicy.create!(assessor: Current.user, local_policy: self)
  end

  def completed?
    status == "complete"
  end
end
