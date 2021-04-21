class DescriptionChangeRequest < ApplicationRecord
  belongs_to :planning_application
  belongs_to :user

  validates :proposed_description, presence: true

  scope :open, -> { where(state: "open") }

  def response_due
    created_at + 15.days
  end

  def days_until_response_due
    (response_due.to_date - Time.zone.today).to_i
  end
end
