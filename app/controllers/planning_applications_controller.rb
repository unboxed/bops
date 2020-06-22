# frozen_string_literal: true

class PlanningApplicationsController < AuthenticationController
  include PlanningApplicationDashboardVariables

  before_action :set_planning_application, only: [ :show, :edit, :update ]
  before_action :set_planning_application_dashboard_variables,
                only: [ :show, :edit, :update ]
  before_action :set_decision_determined_at, only: [ :update ]

  def index
    @planning_applications = policy_scope(PlanningApplication.all)
  end

  def show
  end

  def edit
  end

  def update
    if @planning_application.update(planning_application_params)
      decision_notice_mail if current_user.reviewer?
      redirect_to @planning_application
    else
      render :edit
    end
  end

  private

  def set_planning_application
    @planning_application = authorize(PlanningApplication.find(params[:id]))
  end

  def planning_application_params
    params.require(:planning_application).permit(:status)
  end

  def set_decision_determined_at
    if current_user.reviewer? && @planning_application.
        reviewer_decision.determined_at.nil?
      @planning_application.reviewer_decision.update(
        determined_at: Time.current
      )
    end
  end

  def decision_notice_mail
    DecisionMailer.decision_notice_mail(
      @planning_application.reviewer_decision
    ).deliver_now
  end
end
