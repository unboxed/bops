# frozen_string_literal: true

class RedLineBoundaryChangeValidationRequestsController < ValidationRequestsController
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
      @red_line_boundary_change_validation_request.audit!

      flash[:notice] = "Validation request for red line boundary successfully created."
      redirect_to planning_application_validation_requests_path(@planning_application)
    else
      render :new
    end
  end

  private

  def red_line_boundary_change_validation_request_params
    params.require(:red_line_boundary_change_validation_request).permit(:new_geojson, :reason)
  end
end
