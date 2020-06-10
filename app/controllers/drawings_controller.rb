# frozen_string_literal: true

class DrawingsController < ApplicationController
  include PlanningApplicationDashboardVariables

  before_action :set_planning_application
  before_action :set_planning_application_dashboard_variables

  def index
    @drawings = @planning_application.drawings
  end

  private

  def drawing_params
    params.require(:drawing).permit(:name, :plan, :planning_application_id)
  end

  def set_planning_application
    @planning_application = PlanningApplication.find(
      params[:planning_application_id]
    )
  end
end
