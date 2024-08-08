# frozen_string_literal: true

class PolicySection < ApplicationRecord
  belongs_to :new_policy_class
  has_many :planning_application_policy_sections, dependent: :restrict_with_error
  has_many :planning_applications, through: :planning_application_policy_sections

  with_options presence: true do
    validates :section, uniqueness: {scope: :new_policy_class}
    validates :description
  end
end
