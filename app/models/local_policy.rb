# frozen_string_literal: true

class LocalPolicy < ApplicationRecord
  belongs_to :planning_application

  has_many :local_policy_areas, dependent: :destroy
  has_many :reviews, as: :owner, dependent: :destroy, class_name: "Review"

  before_update :create_review!, if: :should_create_review?

  accepts_nested_attributes_for :local_policy_areas, :reviews

  validates_associated :local_policy_areas
  validates :local_policy_areas, presence: true, if: :completed?

  def current_review
    reviews.where.not(id: nil).order(:created_at).last
  end

  def review_local_policies_with_comments
    reviews.where.not("comment = '' OR comment IS NULL").order(:created_at)
  end

  def create_review!
    return unless Current.user.assessor?

    reviews.create!(assessor: Current.user, owner_type: "LocalPolicy", owner_id: id, status: "complete")
  end

  private

  def should_create_review?
    return if current_review.nil?
    current_review.status_changed? && current_review.status_change == %w[to_be_reviewed complete]
  end

  def completed?
    return if reviews.none?

    current_review&.status == "complete" || reviews.last.status == "complete"
  end
end
