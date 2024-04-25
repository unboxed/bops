# frozen_string_literal: true

class InformativeSet < ApplicationRecord
  belongs_to :planning_application
  has_many :reviews, as: :owner, dependent: :destroy, class_name: "Review"
  has_many :informatives, -> { order(position: :asc) }, dependent: :destroy

  accepts_nested_attributes_for :reviews

  after_update :maybe_create_review

  def current_review
    reviews.order(:created_at).last
  end

  private

  def maybe_create_review
    return if current_review.nil?
    return unless current_review.status == "updated" && current_review.review_status == "to_be_reviewed"

    create_review
  end

  def create_review
    Review.create!(assessor: Current.user, owner_type: "InformativeSet", owner_id: id, status: "complete")
  end
end
