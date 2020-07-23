# frozen_string_literal: true

class PlanningApplicationPolicy < ApplicationPolicy
  self.editors = %w[assessor reviewer admin]

  alias_method :confirm?, :editor?
  alias_method :validate_step?, :editor?
  alias_method :archive?, :editor?

  def show_all?
    user.assessor?
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

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user  = user
      @scope = scope
    end

    def resolve
      if user.admin? || user.reviewer?
        scope.all
      elsif user.assessor?
        scope.where(
          PlanningApplication.arel_table[:user_id].eq(@user.id).or(
            PlanningApplication.arel_table[:user_id].eq(nil)))
      end
    end
  end
end
