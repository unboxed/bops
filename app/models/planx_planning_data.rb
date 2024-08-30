# frozen_string_literal: true

class PlanxPlanningData < ApplicationRecord
  belongs_to :planning_application

  def params_v2
    self[:params_v2]&.with_indifferent_access
  end
end
