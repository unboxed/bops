# frozen_string_literal: true

class PlanningApplicationPolicy < ApplicationPolicy
  self.editors = %w[assessor reviewer]

  alias_method :confirm?, :editor?
  alias_method :validate_step?, :editor?
  alias_method :archive?, :editor?
  alias_method :confirm_new?, :editor?
  alias_method :edit_numbers?, :editor?
  alias_method :assess?, :editor?
  alias_method :determine?, :editor?
  alias_method :request_correction?, :editor?
  alias_method :update_numbers?, :editor?

  def show?
    (super || signed_in_viewer?) && record.local_authority_id == user.local_authority_id
  end

  def index?
    (super || signed_in_viewer?) && record.local_authority_id == user.local_authority_id
  end

  def edit?
    (super || signed_in_editor?) && record.local_authority_id == user.local_authority_id
  end

  def permitted_statuses
    if @user.assessor?
      [ "awaiting_determination" ]
    elsif @user.reviewer?
      [ "determined" ]
    else
      []
    end
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope.where(local_authority_id: user.local_authority_id)
    end
  end
end
