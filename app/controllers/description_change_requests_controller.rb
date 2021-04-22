class DescriptionChangeRequestsController < ApplicationController
  before_action :set_planning_application, only: %i[new create show]

  def new
    @description_change_request = @planning_application.description_change_requests.new
  end

  def create
    @description_change_request = @planning_application.description_change_requests.new(description_change_request_params)
    @description_change_request.user = current_user

    if @description_change_request.save
      flash[:notice] = "Change request for description successfully sent."
      redirect_to validate_documents_form_planning_application_path(@planning_application)
    else
      render :new
    end
  end

  def show
    @description_change_request = DescriptionChangeRequest.find(params[:id])
  end

private

  def description_change_request_params
    params.require(:description_change_request).permit(:proposed_description)
  end

  def set_planning_application
    @planning_application = PlanningApplication.find(params[:planning_application_id])
  end
end
