# frozen_string_literal: true

class PolicySchedule < ApplicationRecord
  has_many :policy_parts, dependent: :destroy

  validates :number, presence: true, uniqueness: true
end
