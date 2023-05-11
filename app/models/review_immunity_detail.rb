# frozen_string_literal: true

class ReviewImmunityDetail < ApplicationRecord
  class NotCreatableError < StandardError; end

  DECISIONS = %w[Yes No].freeze

  belongs_to :immunity_detail

  with_options class_name: "User", optional: true do
    belongs_to :assessor
    belongs_to :reviewer
  end

  with_options presence: true do
    validates :decision, :decision_reason
    validates :summary, if: :decision_is_immune?
  end

  enum status: {
    in_progress: "in_progress",
    complete: "complete",
    to_be_reviewed: "to_be_reviewed"
  }

  enum review_status: {
    review_not_started: "review_not_started",
    review_in_progress: "review_in_progress",
    review_complete: "review_complete"
  }

  validates :decision, inclusion: { in: DECISIONS }

  before_create :ensure_no_open_review_immunity_detail_response!
  before_update :set_status_to_be_reviewed, if: :reviewer_comment?
  before_update :set_reviewer_edited, if: :decision_reason_changed?

  scope :not_accepted, -> { where(accepted: false).order(created_at: :asc) }
  scope :reviewer_not_accepted, -> { not_accepted.where.not(reviewed_at: nil) }
  scope :with_reviewer_comment, -> { where.not(reviewer_comment: nil) }
  scope :not_review_in_progress, -> { where.not(review_status: "review_in_progress") }
  scope :returned, -> { with_reviewer_comment.not_review_in_progress.where(accepted: false) }

  def decision_is_immune?
    decision == "Yes"
  end

  def decision_is_not_immune?
    decision == "No"
  end

  def update_required?
    review_complete? && !accepted
  end

  def review_started?
    review_in_progress? || review_complete?
  end

  private

  def set_status_to_be_reviewed
    return if to_be_reviewed?
    return if review_in_progress?
    return if accepted

    update!(status: "to_be_reviewed")
  end

  def set_reviewer_edited
    return if reviewer_edited
    return unless reviewer && accepted

    update!(reviewer_edited: true)
  end

  def reviewer_is_present?
    return unless reviewer_comment?
    return if reviewer

    errors.add(:base, "Reviewer must be present when returning to officer with a comment")
  end

  def ensure_no_open_review_immunity_detail_response!
    last_review_immunity_detail = immunity_detail.current_review_immunity_detail
    return unless last_review_immunity_detail
    return if last_review_immunity_detail.reviewed_at?

    raise NotCreatableError,
          "Cannot create a review immunity detail response when there is already an open response"
  end
end
