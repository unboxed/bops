# frozen_string_literal: true

class DecisionPolicy < ApplicationPolicy
  self.editors = %w[assessor reviewer admin]
end
