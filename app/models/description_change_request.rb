# frozen_string_literal: true

class DescriptionChangeRequest < ApplicationRecord
  include ChangeRequest
  before_create :set_previous_application_description

  belongs_to :planning_application
  belongs_to :user

  before_create :set_sequence

  validates :proposed_description, presence: true
  validate :rejected_reason_is_present?

  scope :open, -> { where(state: "open") }

  def rejected_reason_is_present?
    if approved == false && rejection_reason.blank?
      errors.add(:base, "Please include a comment for the case officer to indicate why the description change has been rejected.")
    end
  end

  def set_previous_application_description
    self.previous_description = planning_application.description
  end

  def set_sequence
    change_requests = PlanningApplication.find(planning_application.id).description_change_requests
    increment_sequence(change_requests)
  end
end
