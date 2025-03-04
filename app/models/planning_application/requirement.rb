# frozen_string_literal: true

class PlanningApplication::Requirement < ApplicationRecord
  belongs_to :planning_application
  belongs_to :requirement
end
