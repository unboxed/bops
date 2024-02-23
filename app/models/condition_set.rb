# frozen_string_literal: true

class ConditionSet < ApplicationRecord
  belongs_to :planning_application
  has_many :reviews, as: :owner, dependent: :destroy, class_name: "Review"
  has_many :conditions, extend: ConditionsExtension, dependent: :destroy
  has_many :validation_requests, through: :conditions

  accepts_nested_attributes_for :conditions, allow_destroy: true
  accepts_nested_attributes_for :reviews

  after_update :maybe_create_review

  def current_review
    reviews.order(:created_at).last
  end

  def latest_validation_request
    validation_requests.max_by(&:notified_at)
  end

  def latest_validation_requests
    validation_requests.group_by(&:condition_id).map { |id, vr| vr.max_by(&:notified_at) }
  end

  def latest_active_validation_requests
    latest_validation_requests.select { |vr| vr.state != "cancelled" }
  end

  private

  def maybe_create_review
    return if current_review.nil?
    return unless current_review.status == "updated" && current_review.review_status == "to_be_reviewed"

    create_review
  end

  def create_review
    Review.create!(assessor: Current.user, owner_type: "ConditionSet", owner_id: id, status: "complete")
  end
end
