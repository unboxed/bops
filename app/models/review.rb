# frozen_string_literal: true

class Review < ApplicationRecord
  class NotCreatableError < StandardError; end

  belongs_to :reviewable, polymorphic: true

  with_options class_name: "User", optional: true do
    belongs_to :assessor
    belongs_to :reviewer
  end

  before_update :set_status_to_be_reviewed, if: :comment?

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
end
