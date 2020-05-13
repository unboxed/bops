# frozen_string_literal: true

class PlanningApplicationsController < AuthenticationController
  def index
    @planning_applications = policy_scope(PlanningApplication.all)
  end

  def show
    @planning_application = authorize(PlanningApplication.find(params[:id]))
    @site = @planning_application.site
    @agent = @planning_application.agent if @planning_application.agent
    @applicant = @planning_application.applicant
  end
end
