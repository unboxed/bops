# frozen_string_literal: true

class PlanningApplicationPolicy < ApplicationPolicy
  self.editors = %w[assessor reviewer admin]

  alias_method :confirm?, :editor?
  alias_method :validate_step?, :editor?
  alias_method :archive?, :editor?

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

  def confirm_new?
    signed_in_editor?
  end

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
