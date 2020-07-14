# frozen_string_literal: true

class PlanningApplicationPolicy < ApplicationPolicy
  self.editors = %w[assessor reviewer admin]

  alias_method :confirm?, :editor?
  alias_method :validate_step?, :editor?
  alias_method :archive?, :editor?

  def unpermitted_statuses
    PlanningApplication.statuses.keys - permitted_statuses
  end

  def permitted_statuses
    if @user.assessor?
      [ "awaiting_determination" ]
    elsif @user.reviewer? || @user.admin?
      [ "determined" ]
    else
      []
    end
  end
end
