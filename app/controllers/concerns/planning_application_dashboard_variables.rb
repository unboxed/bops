# frozen_string_literal: true

module PlanningApplicationDashboardVariables
  extend ActiveSupport::Concern

  def set_planning_application_dashboard_variables
    @site = @planning_application.site
    @policy_evaluation = @planning_application.policy_evaluation
  end
end
