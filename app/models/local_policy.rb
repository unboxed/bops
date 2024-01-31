# frozen_string_literal: true

class LocalPolicy < ApplicationRecord
  belongs_to :planning_application

  has_many :local_policy_areas, dependent: :destroy
  has_many :review_local_policies, dependent: :destroy
  has_many :reviews, as: :owner, dependent: :destroy, class_name: "Review"

  after_create :create_review
  before_update :maybe_create_review

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

  def current_review
    reviews.where.not(id: nil).order(:created_at).last
  end

  def review_local_polices_with_comments
    reviews.where.not("comment = '' OR comment IS NULL").order(:created_at)
  end

  private

  def maybe_create_review
    return unless status_changed? && status_change == %w[to_be_reviewed complete]

    create_review
  end

  def create_review
    Review.create!(assessor: Current.user, owner_type: "LocalPolicy", owner_id: id)
  end

  def completed?
    status == "complete"
  end
end
