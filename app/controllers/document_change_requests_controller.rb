class DocumentChangeRequestsController < ApplicationController
  def new
    @document_change_request = planning_application.document_change_requests.new
  end

  def create
    # check params and redirect to correct controller
  end

private

  def planning_application
    @planning_application = PlanningApplication.find(params[:planning_application_id])
  end
end
