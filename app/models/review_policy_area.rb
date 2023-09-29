# frozen_string_literal: true

class ReviewPolicyArea < ApplicationRecord
  class NotCreatableError < StandardError; end

  DECISIONS = %w[Yes No].freeze

  belongs_to :policy_area

  with_options class_name: "User", optional: true do
    belongs_to :assessor
    belongs_to :reviewer
  end

before_update :set_status_to_be_reviewed, if: :reviewer_comment?
  before_update :set_reviewer_edited, if: :assessment_changed?

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

  def assessment_changed?
    policy_area.assessment_changed?
  end
end
