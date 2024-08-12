# frozen_string_literal: true

class PlanningApplicationPolicySection < ApplicationRecord
  belongs_to :planning_application
  belongs_to :policy_section

  validates :status, presence: true

  enum(
    status: {
      complies: "complies",
      does_not_comply: "does_not_comply",
      to_be_determined: "to_be_determined"
    },
    _default: :to_be_determined
  )
end
