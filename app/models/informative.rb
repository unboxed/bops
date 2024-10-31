# frozen_string_literal: true

class Informative < ApplicationRecord
  belongs_to :informative_set
  acts_as_list scope: :informative_set

  validates :title, presence: true, uniqueness: {scope: :informative_set}
  validates :text, presence: true
  validate :ensure_planning_application_not_closed_or_cancelled

  attribute :reviewer_edited, :boolean, default: false
  delegate :current_review, to: :informative_set
  delegate :not_started?, to: :current_review, prefix: true
  delegate :planning_application, to: :informative_set

  before_update if: :reviewer_edited? do
    current_review.update!(reviewer_edited: true)
  end

  after_create if: :current_review_not_started? do
    current_review.update!(status: "in_progress")
  end

  def ensure_planning_application_not_closed_or_cancelled
    errors.add(:base, "Cannot modify informatives when planning application has been closed or cancelled") if planning_application.closed_or_cancelled?
  end
end
