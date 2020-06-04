# frozen_string_literal: true

class Decision < ApplicationRecord
  enum status: { pending: 0, granted: 1, refused: 2 }

  belongs_to :planning_application
  belongs_to :user

  validates :status, inclusion: { in: ["granted", "refused"],
    message: "Please select Yes or No" }, on: :update

  def comment_made?
    granted? && comment_met.present? || refused? && comment_unmet.present?
  end
end
