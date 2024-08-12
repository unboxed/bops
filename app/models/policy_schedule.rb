# frozen_string_literal: true

class PolicySchedule < ApplicationRecord
  has_many :policy_parts, dependent: :restrict_with_error

  validates :number, presence: true, uniqueness: true
end
