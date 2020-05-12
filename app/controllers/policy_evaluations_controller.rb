# frozen_string_literal: true

class PolicyEvaluationsController < ApplicationController
  before_action :set_planning_application

  def new
    @policy_evaluation = @planning_application.build_policy_evaluation
    @site = @planning_application.site
    @agent = @planning_application.agent if @planning_application.agent
    @applicant = @planning_application.applicant
  end

  def create
    @policy_evaluation = @planning_application.build_policy_evaluation(policy_evaluation_params)

    if @policy_evaluation.save
      redirect_to @planning_application
    else
      @site = @planning_application.site
      @agent = @planning_application.agent if @planning_application.agent
      @applicant = @planning_application.applicant

      render :new
    end
  end

  def edit
    @policy_evaluation = @planning_application.policy_evaluation
    @site = @planning_application.site
    @agent = @planning_application.agent if @planning_application.agent
    @applicant = @planning_application.applicant
  end

  def update
    @policy_evaluation = @planning_application.policy_evaluation

    if @policy_evaluation.update(policy_evaluation_params)
      redirect_to @planning_application
    else
      @site = @planning_application.site
      @agent = @planning_application.agent if @planning_application.agent
      @applicant = @planning_application.applicant

      render :edit
    end
  end

  private

  def set_planning_application
    @planning_application = PlanningApplication.find(params[:planning_application_id])
  end

  def policy_evaluation_params
    params.fetch(:policy_evaluation, {}).permit(:requirements_met)
  end
end
