# frozen_string_literal: true

class NewPolicyClass < ApplicationRecord
  belongs_to :policy_part
  has_many :policy_sections, dependent: :destroy
  has_many :planning_application_policy_classes, dependent: :restrict_with_error
  has_many :planning_applications, through: :planning_application_policy_classes

  validates :section, presence: true, uniqueness: {scope: :policy_part}
  validates :name, presence: true
end