# frozen_string_literal: true

class DecisionsController < AuthenticationController
  include PlanningApplicationDashboardVariables

  before_action :set_planning_application
  before_action :set_planning_application_dashboard_variables
  before_action :assign_assessor

  def new
    @decision = @planning_application.decisions.build(user: current_user)
  end

  def create
    @decision = @planning_application.decisions.build(
      decision_params.merge(user: current_user)
    )

    if @decision.save
      set_awaiting_correction
      redirect_to @planning_application
    else
      render :new
    end
  end

  def edit
    set_decision_to_current_user(current_user)
  end

  def update
    set_decision_to_current_user(current_user)

    if @decision.update(decision_params.merge(user: current_user))
      set_awaiting_correction
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

  def assign_assessor
    if current_user.assessor? && @planning_application.user.nil?
      @planning_application.update(user_id: current_user[:id])
    end
  end

  def set_awaiting_correction
    if @planning_application.awaiting_determination? &&
        @planning_application.reviewer_disagrees_with_assessor?

      @planning_application.update_and_timestamp_status(:awaiting_correction)
    end
  end

  def set_decision_to_current_user(current_user)
    if current_user.assessor?
      @decision = @planning_application.assessor_decision
    else
      @decision = @planning_application.reviewer_decision
    end
  end

  def decision_params
    params.fetch(:decision, {}).permit(
      :status, :public_comment, :private_comment
    )
  end
end
