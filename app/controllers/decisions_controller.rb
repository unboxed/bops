# frozen_string_literal: true

class DecisionsController < AuthenticationController
  include PlanningApplicationDashboardVariables

  before_action :set_planning_application
  before_action :set_planning_application_dashboard_variables, only: [ :new ]

  def new
    @decision = @planning_application.decisions.build(user: current_user)
  end

  def create
    @planning_application.decisions.create(
      user: current_user,
      status: :granted
    )
    @planning_application.awaiting_determination!

    redirect_to @planning_application
  end

  private

  def set_planning_application
    @planning_application = authorize(
      PlanningApplication.find(params[:planning_application_id])
    )
  end
end
