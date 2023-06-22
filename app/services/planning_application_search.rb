# frozen_string_literal: true

class PlanningApplicationSearch
  include ActiveModel::Model
  include ActiveModel::Attributes

  def initialize(params = {})
    @view = params.fetch(:q, nil)
  end

  def call
    view_mine? ? my_applications : all_applications
  end

  private

  attr_reader :view

  def view_mine?
    exclude_others? && assessor?
  end

  def my_applications
    all_applications.for_user_and_null_users(current_user.id)
  end

  def all_applications
    @all_applications ||= local_authority.planning_applications.includes([:application_type]).by_created_at_desc
  end

  def exclude_others?
    view == "exclude_others"
  end

  def current_user
    @current_user ||= Current.user
  end

  def assessor?
    current_user.assessor?
  end

  def local_authority
    @local_authority = current_user.local_authority
  end
end
