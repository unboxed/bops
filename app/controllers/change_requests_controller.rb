class ChangeRequestsController < ApplicationController
  def new
    @planning_application = PlanningApplication.find(params[:planning_application_id])
  end

  def create
    @planning_application = PlanningApplication.find(params[:planning_application_id])

    if params[:change_request] == "description_change"
      redirect_to new_planning_application_description_change_request_path
    elsif params[:change_request] == "replacement_document"
      redirect_to new_planning_application_document_change_request_path
    else
      flash[:error] = "You must select a change request type to proceed."
      render "new"
    end
  end
end
