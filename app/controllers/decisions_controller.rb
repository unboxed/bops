# frozen_string_literal: true

class DecisionsController < AuthenticationController
  include PlanningApplicationDashboardVariables

  before_action :set_planning_application
  before_action :set_planning_application_dashboard_variables

  def new
    @decision = @planning_application.decisions.build(user: current_user)
  end

  def create
    if current_user.assessor?
      @planning_application.decisions.create(
        user: current_user,
        granted: true
      )
      @planning_application.awaiting_determination!

      redirect_to @planning_application
    elsif current_user.reviewer?
      @decision = @planning_application.decisions.build(
        user: current_user,
        granted: decision_params[:granted]
      )

      if @decision.save
        @planning_application.determined!

        redirect_to @planning_application
      else
        render :new
      end
    end
  end

  private

  def set_planning_application
    @planning_application = authorize(
      PlanningApplication.find(params[:planning_application_id])
    )
  end

  def decision_params
    params.fetch(:decision, {}).permit(:granted)
  end
end
