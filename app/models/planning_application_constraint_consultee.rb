# frozen_string_literal: true

class PlanningApplicationConstraintConsultee < ApplicationRecord
  belongs_to :planning_application_constraint, inverse_of: :planning_application_constraint_consultees
  belongs_to :consultee, inverse_of: :planning_application_constraint_consultees

  validates :consultee_id, uniqueness: {scope: :planning_application_constraint_id}
end
