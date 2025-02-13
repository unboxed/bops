# frozen_string_literal: true

class PolicySection < ApplicationRecord
  TITLES = [
    "Permitted development",
    "Development not permitted",
    "Conditions",
    "Interpretation",
    "Other"
  ].freeze

  belongs_to :policy_class
  has_many :planning_application_policy_sections, dependent: :restrict_with_error
  has_many :planning_applications, through: :planning_application_policy_sections

  with_options presence: true do
    validates :section, uniqueness: {scope: :policy_class}
    validates :description
  end

  validates :title, inclusion: {in: TITLES}

  scope :grouped_and_ordered_by_title, -> {
    group_by(&:title)
  }

  def full_section
    "#{policy_class.section}.#{section}"
  end

  def planning_application_policy_section
    planning_application_policy_sections.last
  end
end
