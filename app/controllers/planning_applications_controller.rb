# frozen_string_literal: true

class PlanningApplicationsController < AuthenticationController
  def index
    @planning_applications = PlanningApplication.all

    policy_scope(@planning_applications)
  end

  def show
    @planning_application = PlanningApplication.find(params[:id])
    @site = @planning_application.site
    @agent = @planning_application.agent if @planning_application.agent
    @applicant = @planning_application.applicant

    authorize(@planning_application)
  end
end
