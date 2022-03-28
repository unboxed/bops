# frozen_string_literal: true

class RedLineBoundaryChangeValidationRequestsController < ValidationRequestsController
  include ValidationRequests

  before_action :set_red_line_boundary_validation_request, only: %i[show edit update]

  def new
    @red_line_boundary_change_validation_request = @planning_application.red_line_boundary_change_validation_requests.new
  end

  def show; end

  def create
    @red_line_boundary_change_validation_request = RedLineBoundaryChangeValidationRequest.new(red_line_boundary_change_validation_request_params
                                                                             .merge!({ planning_application_id: @planning_application.id }))
    @red_line_boundary_change_validation_request.user = current_user

    if @red_line_boundary_change_validation_request.save
      email_and_timestamp(@red_line_boundary_change_validation_request) if @planning_application.invalidated?

      redirect_to planning_application_validation_tasks_path(@planning_application),
                  notice: "Validation request for red line boundary successfully created."
    else
      render :new
    end
  end

  def edit; end

  def update
    if @red_line_boundary_change_validation_request.update(red_line_boundary_change_validation_request_params)
      redirect_to planning_application_validation_tasks_path(@planning_application),
                  notice: "Validation request for red line boundary successfully updated"
    else
      render :edit
    end
  end

  private

  def red_line_boundary_change_validation_request_params
    params.require(:red_line_boundary_change_validation_request).permit(:new_geojson, :reason)
  end

  def set_red_line_boundary_validation_request
    @red_line_boundary_change_validation_request = @planning_application.red_line_boundary_change_validation_requests.find(params[:id])
  end
end
