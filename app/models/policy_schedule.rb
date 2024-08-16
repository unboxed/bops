# frozen_string_literal: true

class PolicySchedule < ApplicationRecord
  has_many :policy_parts, -> { order(:number) }, dependent: :restrict_with_error

  validates :number, presence: true, uniqueness: true, numericality: {greater_than_or_equal_to: 1, less_than_or_equal_to: 4}

  attr_readonly :number

  scope :by_number, -> { order(number: :asc) }

  def full_name
    if name.present?
      "Schedule #{number} - #{name}"
    else
      "Schedule #{number}"
    end
  end
end
