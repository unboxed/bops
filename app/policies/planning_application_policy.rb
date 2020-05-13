# frozen_string_literal: true

class PlanningApplicationPolicy < ApplicationPolicy
  self.viewers = %w[assessor reviewer admin]
end
