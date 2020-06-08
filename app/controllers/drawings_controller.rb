# frozen_string_literal: true

class DrawingsController < AuthenticationController
  include PlanningApplicationDashboardVariables

  before_action :set_planning_application
  before_action :set_planning_application_dashboard_variables

  def index
    @drawings = policy_scope(Drawing.where("planning_application_id = ?",
                                           params[:planning_application_id]))
  end

  private

  def drawing_params
    params.require(:drawing).permit(:name, :plan, :planning_application_id)
  end

  def set_planning_application
    @planning_application = authorize(
      PlanningApplication.find(params[:planning_application_id])
    )
  end
end
