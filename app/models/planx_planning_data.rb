# frozen_string_literal: true

class PlanxPlanningData < ApplicationRecord
  belongs_to :planning_application

  validates :entry, presence: true
end
