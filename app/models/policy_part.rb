# frozen_string_literal: true

class PolicyPart < ApplicationRecord
  belongs_to :policy_schedule
  has_many :new_policy_classes, dependent: :destroy

  with_options presence: true do
    validates :number, uniqueness: {scope: :policy_schedule}, numericality: {greater_than_or_equal_to: 1, less_than_or_equal_to: 20}
    validates :name
  end
end
