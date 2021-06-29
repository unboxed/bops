class ChangeRequestsController < ApplicationController
  before_action :set_planning_application

  def index; end

  def new; end

  def create
    case params[:change_request]
    when "description_change"
      redirect_to new_planning_application_description_change_validation_request_path
    when "replacement_document"
      redirect_to new_planning_application_replacement_document_validation_request_path
    when "create_document"
      redirect_to new_planning_application_document_create_request_path
    when "red_line_boundary"
      redirect_to new_planning_application_red_line_boundary_change_request_path
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
