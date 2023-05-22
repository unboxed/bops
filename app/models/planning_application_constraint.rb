# frozen_string_literal: true

class PlanningApplicationConstraint < ApplicationRecord
  belongs_to :planning_application
  belongs_to :planning_application_constraints_query, optional: true
  belongs_to :constraint
end
