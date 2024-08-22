# frozen_string_literal: true

class NewPolicyClass < ApplicationRecord
  belongs_to :policy_part
  has_many :policy_sections, dependent: :destroy
  has_many :planning_application_policy_classes, dependent: :restrict_with_error
  has_many :planning_applications, through: :planning_application_policy_classes

  attr_readonly :section

  with_options presence: true do
    validates :section, uniqueness: {scope: :policy_part}
    validates :name
  end

  validates :url, url: true
end
