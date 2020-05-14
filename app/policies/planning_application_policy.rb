# frozen_string_literal: true

class PlanningApplicationPolicy < ApplicationPolicy
  self.viewers = %w[assessor reviewer admin]

  def show?
    super || signed_in_viewer?
  end

  def index?
    super || signed_in_viewer?
  end
end
