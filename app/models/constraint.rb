# frozen_string_literal: true

class Constraint < ApplicationRecord
  self.inheritance_column = "inheritance_type"

  validates :category, :type, presence: true
  validates :type, uniqueness: { scope: :local_authority }

  belongs_to :local_authority, optional: true

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

  scope :options_for_local_authority, ->(local_authority_id) { where(local_authority_id: [local_authority_id, nil]) }

  class << self
    def grouped_by_category(local_authority_id)
      options_for_local_authority(local_authority_id).group_by(&:category)
    end
  end
end
