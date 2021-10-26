# frozen_string_literal: true

class RedLineBoundaryChangeValidationRequestsController < ValidationRequestsController
  before_action :set_planning_application, only: %i[new create show]

  include ValidationRequests

  def new
    @red_line_boundary_change_validation_request = @planning_application.red_line_boundary_change_validation_requests.new
  end

  def show
    @red_line_boundary_change_validation_request = @planning_application.red_line_boundary_change_validation_requests.find(params[:id])
  end

  def create
    @red_line_boundary_change_validation_request = RedLineBoundaryChangeValidationRequest.new(red_line_boundary_change_validation_request_params
                                                                             .merge!({ planning_application_id: @planning_application.id }))
    @red_line_boundary_change_validation_request.user = current_user

    if @red_line_boundary_change_validation_request.save
      email_and_timestamp(@red_line_boundary_change_validation_request) if @planning_application.invalidated?

      flash[:notice] = "Validation request for red line boundary successfully created."
      if @planning_application.invalidated?
        audit("red_line_boundary_change_validation_request_sent", red_line_boundary_audit_item(@red_line_boundary_change_validation_request),
              @red_line_boundary_change_validation_request.sequence)
      else
        audit("red_line_boundary_change_validation_request_added", red_line_boundary_audit_item(@red_line_boundary_change_validation_request),
              @red_line_boundary_change_validation_request.sequence)
      end
      redirect_to planning_application_validation_requests_path(@planning_application)
    else
      render :new
    end
  end

  private

  def red_line_boundary_change_validation_request_params
    params.require(:red_line_boundary_change_validation_request).permit(:new_geojson, :reason)
  end

  def set_planning_application
    @planning_application = PlanningApplication.find(params[:planning_application_id])
  end

  def red_line_boundary_audit_item(validation_request)
    validation_request.reason
  end
end
