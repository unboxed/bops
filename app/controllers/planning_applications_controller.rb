# frozen_string_literal: true

class PlanningApplicationsController < AuthenticationController
  include PlanningApplicationDashboardVariables

  before_action :set_planning_application, only: [ :show ]
  before_action :set_planning_application_dashboard_variables, only: [ :show ]

  def index
    @planning_applications = policy_scope(PlanningApplication.all)
  end

  def show
  end

  private

  def set_planning_application
    @planning_application = authorize(PlanningApplication.find(params[:id]))
  end
end
