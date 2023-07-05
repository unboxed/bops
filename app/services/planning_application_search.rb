# frozen_string_literal: true

class PlanningApplicationSearch
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :view, :enum, values: %w[all mine], default: "mine"

  def initialize(params = ActionController::Parameters.new)
    super(filter_params(params))
  end

  def call
    view_mine? ? my_applications : all_applications
  end

  def exclude_others?
    view == "mine"
  end

  def all_applications_tab_title
    I18n.t(all_applications_title_key, scope: "planning_applications.tabs")
  end

  private

  def filter_params(params)
    params.permit(:view)
  end

  def view_mine?
    exclude_others? && assessor?
  end

  def all_applications_title_key
    exclude_others? ? :all_your_applications : :all_applications
  end

  def my_applications
    all_applications.for_user_and_null_users(current_user.id)
  end

  def all_applications
    @all_applications ||= local_authority.planning_applications.includes([:application_type]).by_created_at_desc
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
