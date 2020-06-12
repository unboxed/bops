# frozen_string_literal: true

class PlanningApplicationPolicy < ApplicationPolicy
  self.editors = %w[assessor reviewer admin]

  def show?
    super || signed_in_viewer?
  end

  def index?
    super || signed_in_viewer?
  end

  def edit?
    super || signed_in_editor?
  end

  def update?
    super || signed_in_editor?
  end
end
