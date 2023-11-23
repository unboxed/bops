# frozen_string_literal: true

class PlanxPlanningData < ApplicationRecord
  belongs_to :planning_application

  validates :session_id, uniqueness: true, allow_nil: true
end
