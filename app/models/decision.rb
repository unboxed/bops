# frozen_string_literal: true

class Decision < ApplicationRecord
  enum status: { granted: 0, refused: 1 }

  belongs_to :planning_application
  belongs_to :user

  validates :status, inclusion: { in: %w[granted refused],
                                  message: "Please select Yes or No" }

  validate :validate_public_comment, :validate_private_comment

  def refused_with_public_comment?
    refused? && public_comment.present?
  end

  def validate_public_comment
    if refused? && user.assessor? && public_comment.blank?
      errors.add(
        :public_comment,
        "Please provide which GDPO policy (or policies) have not been met.",
      )
    end
  end

  def validate_private_comment
    if disagrees_with_assessor? && user.reviewer? && private_comment.blank?
      errors.add(
        :private_comment,
        "Please enter a reason in the box.",
      )
    end
  end

private

  def disagrees_with_assessor?
    status != planning_application.assessor_decision&.status &&
      planning_application.assessor_decision.present? && status.present?
  end
end
