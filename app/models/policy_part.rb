# frozen_string_literal: true

class PolicyPart < ApplicationRecord
  belongs_to :policy_schedule
  has_many :new_policy_classes, dependent: :destroy

  with_options presence: true do
    validates :number, uniqueness: {scope: :policy_schedule}
    validates :name
  end
end
