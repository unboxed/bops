# frozen_string_literal: true

module PlanningApplicationDashboardVariables
  extend ActiveSupport::Concern

  def set_planning_application_dashboard_variables
    @site = @planning_application.site
    @agent = @planning_application.agent if @planning_application.agent
    @applicant = @planning_application.applicant
    @policy_evaluation = @planning_application.policy_evaluation
  end
end
