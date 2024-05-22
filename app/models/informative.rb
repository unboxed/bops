# frozen_string_literal: true

class Informative < ApplicationRecord
  belongs_to :informative_set
  acts_as_list scope: :informative_set

  validates :title, presence: true, uniqueness: {scope: :informative_set}
  validates :text, presence: true

  attribute :reviewer_edited, :boolean, default: false
  delegate :current_review, to: :informative_set
  delegate :not_started?, to: :current_review, prefix: true

  before_update if: :reviewer_edited? do
    current_review.update!(reviewer_edited: true)
  end

  after_create if: :current_review_not_started? do
    current_review.update!(status: "in_progress")
  end
end
