# frozen_string_literal: true

class DecisionsController < AuthenticationController
  include PlanningApplicationDashboardVariables

  before_action :set_planning_application
  before_action :set_planning_application_dashboard_variables
  before_action :attach_officer

  def new
    @decision = @planning_application.decisions.build(user: current_user)
  end

  def create
    @decision = @planning_application.decisions.build(
      decision_params.merge(user: current_user)
    )

    if @decision.save
      redirect_to @planning_application
    else
      render :new
    end
  end

  def edit
    if current_user.assessor?
      @decision = @planning_application.assessor_decision
    else
      @decision = @planning_application.reviewer_decision
    end
  end

  def update
    if current_user.assessor?
      @decision = @planning_application.assessor_decision
    else
      @decision = @planning_application.reviewer_decision
    end

    if @decision.update(decision_params.merge(user: current_user))
      redirect_to @planning_application
    else
      render :edit
    end
  end

  private

  def set_planning_application
    @planning_application = authorize(
      PlanningApplication.find(params[:planning_application_id])
    )
  end

  def attach_officer
    if current_user.assessor? && @planning_application.user.nil?
      @planning_application.update(user_id: current_user[:id])
    end
  end

  def decision_params
    params.fetch(:decision, {}).permit(:status, :comment_met, :comment_unmet)
  end
end
