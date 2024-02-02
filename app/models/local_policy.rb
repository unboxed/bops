# frozen_string_literal: true

class LocalPolicy < ApplicationRecord
  belongs_to :planning_application

  has_many :local_policy_areas, dependent: :destroy
  has_many :reviews, as: :owner, dependent: :destroy, class_name: "Review"

  before_update :maybe_create_review

  AREAS = %w[design impact_on_neighbours other].freeze

  accepts_nested_attributes_for :local_policy_areas, :reviews
  
  validates_associated :local_policy_areas
  validates_presence_of :local_policy_areas

  def current_review
    reviews.where.not(id: nil).order(:created_at).last
  end

  def review_local_polices_with_comments
    reviews.where.not("comment = '' OR comment IS NULL").order(:created_at)
  end

  private

  def maybe_create_review
    return unless status_changed? && status_change == %w[to_be_reviewed complete]

    create_review_local_policy
  end

  def create_review
    Review.create!(assessor: Current.user, owner_type: "LocalPolicy", owner_id: id)
  end

  def completed?
    review.status == "complete"
  end
end
