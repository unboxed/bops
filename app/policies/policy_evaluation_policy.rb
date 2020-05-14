# frozen_string_literal: true

class PolicyEvaluationPolicy < ApplicationPolicy
  self.editors = %w[assessor admin]
end
