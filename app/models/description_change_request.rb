# frozen_string_literal: true

class DescriptionChangeRequest < ApplicationRecord
  before_create :set_previous_application_description

  belongs_to :planning_application
  belongs_to :user

  validates :proposed_description, presence: true
  validate :rejected_reason_is_present?

  scope :open, -> { where(state: "open") }
  scope :order_by_latest, -> { order(created_at: :desc) }

  def response_due
    15.business_days.after(created_at.to_date)
  end

  def days_until_response_due
    if response_due > Time.zone.today
      Time.zone.today.business_days_until(response_due)
    else
      -response_due.business_days_until(Time.zone.today)
    end
  end

  def rejected_reason_is_present?
    if approved == false
      errors.add(:base, "Please include a comment for the case officer to indicate why the description change has been rejected.") if rejection_reason.blank?
    end
  end

  def set_previous_application_description
    self.previous_description = planning_application.description
  end
end
