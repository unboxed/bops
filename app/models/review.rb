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

  with_options presence: true do
    validates :status, :review_status
    validates :decision, :decision_reason, if: -> { owner_is_immunity_detail? && enforcement? }
    validates :summary, if: -> { owner_is_immunity_detail? && decision_is_immune? }
  end

  accepts_nested_attributes_for :local_policy_areas

  before_create :ensure_no_open_evidence_review_immunity_detail_response!, if: :owner_is_immunity_detail?
  before_create :ensure_no_open_enforcement_review_immunity_detail_response!, if: :owner_is_immunity_detail?
  before_update :set_status_to_be_reviewed, if: :comment?
  before_update :set_reviewer_edited, if: -> { owner_is_local_policy? && assessment_changed? }
  before_update :set_reviewed_at, if: :reviewer_present?

  enum action: {
    accepted: "accepted",
    edited_and_accepted: "edited_and_accepted",
    rejected: "rejected"
  }

  enum(
    status: {
      not_started: "not_started",
      in_progress: "in_progress",
      to_be_reviewed: "to_be_reviewed",
      complete: "complete",
      updated: "updated"
    },
    _default: "not_started"
  )

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
    review_complete? || to_be_reviewed?
  end

  def decision_is_immune?
    return if specific_attributes.nil?

    specific_attributes["decision"] == "Yes"
  end

  def decision_is_not_immune?
    return if specific_attributes.nil?

    specific_attributes["decision"] == "No"
  end

  private

  def set_reviewed_at
    Time.zone.now
  end

  def reviewer_present?
    return if reviewer.nil?

    action_was.nil?
  end

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

  def owner_is_immunity_detail?
    owner_type == "ImmunityDetail"
  end

  def assessment_changed?
    owner.local_policy_areas.each do |local_policy_area|
      local_policy_area.saved_changes.any?
    end
  end

  def enforcement?
    return if specific_attributes.nil?

    specific_attributes["review_type"] == "enforcement"
  end

  def evidence?
    return if specific_attributes.nil?

    specific_attributes["review_type"] == "evidence"
  end

  def ensure_no_open_evidence_review_immunity_detail_response!
    return if enforcement?

    last_evidence_review_immunity_detail = owner.current_evidence_review_immunity_detail
    return unless last_evidence_review_immunity_detail
    return if last_evidence_review_immunity_detail.reviewed_at?

    raise NotCreatableError,
      "Cannot create an evidence review immunity detail response when there is already an open response"
  end

  def ensure_no_open_enforcement_review_immunity_detail_response!
    return if evidence?

    last_enforcement_review_immunity_detail = owner.current_enforcement_review_immunity_detail
    return unless last_enforcement_review_immunity_detail
    return if last_enforcement_review_immunity_detail.reviewed_at?

    raise NotCreatableError,
      "Cannot create an enforcement review immunity detail response when there is already an open response"
  end
end
