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
    complete: "complete"
  }

  validates :decision, inclusion: { in: DECISIONS }

  before_create :ensure_no_open_review_immunity_detail_response!

  scope :not_accepted, -> { where(accepted: false).order(created_at: :asc) }
  scope :reviewer_not_accepted, -> { not_accepted.where.not(reviewed_at: nil) }

  def decision_is_immune?
    decision == "Yes"
  end

  def decision_is_not_immune?
    decision == "No"
  end

  private

  def ensure_no_open_review_immunity_detail_response!
    last_review_immunity_detail = immunity_detail.current_review_immunity_detail
    return unless last_review_immunity_detail
    return if last_review_immunity_detail.reviewed_at?

    raise NotCreatableError,
          "Cannot create a review immunity detail response when there is already an open response"
  end
end
