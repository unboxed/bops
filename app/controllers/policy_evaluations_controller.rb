# frozen_string_literal: true

class PolicyEvaluationsController < ApplicationController
  include PlanningApplicationDashboardVariables

  before_action :set_planning_application
  before_action :set_planning_application_dashboard_variables

  def show
    @policy_evaluation = @planning_application.policy_evaluation
  end

  def update
    @policy_evaluation = @planning_application.policy_evaluation

    if @policy_evaluation.update(policy_evaluation_params)
      redirect_to @planning_application
    else
      render :show
    end
  end

  private

  def set_planning_application
    @planning_application = PlanningApplication.find(
      params[:planning_application_id]
    )

    # TODO: this is temporary, should move to Ripa::PolicyConsiderationBuilder,
    # once we have more knowledge
    unless @planning_application.policy_evaluation
      @planning_application.create_policy_evaluation
    end
  end

  def policy_evaluation_params
    params.fetch(:policy_evaluation, {}).permit(:status)
  end
end
