class ChangeRequestsController < ApplicationController
  before_action :set_planning_application

  def index; end

  def new; end

  def create
    if params[:change_request] == "description_change"
      redirect_to new_planning_application_description_change_request_path
    elsif params[:change_request] == "replacement_document"
      redirect_to new_planning_application_document_change_request_path
    else
      flash[:error] = "You must select a change request type to proceed."
      render "new"
    end
  end

private

  def set_planning_application
    @planning_application = PlanningApplication.find(params[:planning_application_id])
  end
end
