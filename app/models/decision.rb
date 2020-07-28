# frozen_string_literal: true

class Decision < ApplicationRecord
  enum status: { granted: 0, refused: 1 }

  belongs_to :planning_application
  belongs_to :user

  validates :status, inclusion: { in: ["granted", "refused"],
    message: "Please select Yes or No" }

  def refused_with_public_comment?
    refused? && public_comment.present?
  end
end
