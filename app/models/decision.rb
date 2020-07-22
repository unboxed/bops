# frozen_string_literal: true

class Decision < ApplicationRecord
  enum status: { granted: 0, refused: 1 }

  belongs_to :planning_application
  belongs_to :user

  validates :status, inclusion: { in: ["granted", "refused"],
    message: "Please select Yes or No" }

  validate :ensure_correction, on: :update

  def comment_made?
    granted? && comment_met.present? || refused? && comment_unmet.present?
  end

  private

  def ensure_correction
    return unless planning_application.awaiting_determination?
    return unless user.reviewer?
    return if planning_application.reviewer_decision.status ==
        planning_application.assessor_decision.status

    if correction.blank?
      errors.add(:correction, "Please enter a reason in the box")
    end
  end
end
