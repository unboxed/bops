# frozen_string_literal: true

class Constraint < ApplicationRecord
  validates :category, :name, presence: true

  enum category: {
    flooding: "flooding",
    military_and_defence: "military_and_defence",
    ecology: "ecology",
    heritage_and_conservation: "heritage_and_conservation",
    general_policy: "general_policy",
    tree: "tree",
    other: "other",
    local: "local"
  }

  has_many :planning_application_constraints, dependent: :destroy
end
