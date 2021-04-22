# frozen_string_literal: true

class DescriptionChangeRequest < ApplicationRecord
  belongs_to :planning_application
  belongs_to :user

  validates :proposed_description, presence: true

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
end
