# frozen_string_literal: true

class PlanningApplicationsController < AuthenticationController
  include PlanningApplicationDashboardVariables

  before_action :set_planning_application, only: [ :show, :edit, :update ]
  before_action :set_planning_application_dashboard_variables,
                only: [ :show, :edit, :update ]

  def index
    @planning_applications = policy_scope(PlanningApplication.all)
  end

  def show
  end

  def edit
  end

  def update
    if @planning_application.update(planning_application_params)
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
end
