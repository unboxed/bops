# frozen_string_literal: true

class Review < ApplicationRecord
  class NotCreatableError < StandardError; end
  store_accessor :specific_attributes, %w[decision decision_reason summary decision_type removed review_type]

  belongs_to :owner, polymorphic: true, autosave: true

  has_many :local_policy_areas, through: :owner

  with_options class_name: "User", optional: true do
    belongs_to :assessor
    belongs_to :reviewer
  end

  accepts_nested_attributes_for :local_policy_areas

  before_update :set_status_to_be_reviewed, if: :comment?
  before_update :set_reviewer_edited, if: -> { :owner_is_local_policy? && :assessment_changed? }

  enum action: {
    accepted: "accepted",
    edited_and_accepted: "edited_and_accepted",
    rejected: "rejected"
  }

  enum status: {
    complete: "complete",
    in_progress: "in_progress",
    not_started: "not_started",
    to_be_reviewed: "to_be_reviewed",
    updated: "updated"
  }

  enum review_status: {
    review_complete: "review_complete",
    review_in_progress: "review_in_progress",
    review_not_started: "review_not_started"
  }

  scope :evidence, -> { where("specific_attributes->>'review_type' = ?", "evidence") }
  scope :enforcement, -> { where("specific_attributes->>'review_type' = ?", "enforcement") }
  scope :not_accepted, -> { where(action: "rejected").order(created_at: :asc) }
  scope :reviewer_not_accepted, -> { not_accepted.where.not(reviewed_at: nil) }

  validates :comment, presence: true, if: :rejected?

  def complete_or_to_be_reviewed?
    complete? || to_be_reviewed?
  end

  private

  def set_status_to_be_reviewed
    return if to_be_reviewed?
    return if in_progress?
    return if accepted?
    return if updated?

    update!(status: "to_be_reviewed")
  end

  def set_reviewer_edited
    return if reviewer_edited
    return unless reviewer
    return if rejected?

    update!(reviewer_edited: true)
  end

  def owner_is_local_policy?
    owner_type == "LocalPolicy"
  end

  def assessment_changed?
    owner.local_policy_areas.each do |local_policy_area|
      local_policy_area.saved_changes.any?
    end
  end
end
