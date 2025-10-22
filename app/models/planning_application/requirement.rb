# frozen_string_literal: true

class PlanningApplication < ApplicationRecord
  class Requirement < ApplicationRecord
    belongs_to :planning_application
  end
end
