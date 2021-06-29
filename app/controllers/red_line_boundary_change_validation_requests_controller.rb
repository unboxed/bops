class RedLineBoundaryChangeValidationRequestsController < ApplicationController
  before_action :set_planning_application, only: %i[new create show]

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
      send_validation_request_email
      flash[:notice] = "Validation request for red line boundary successfully sent."
      audit("red_line_boundary_change_validation_request_sent", red_line_boundary_audit_item(@red_line_boundary_change_validation_request),
            @red_line_boundary_change_validation_request.sequence)
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

  def send_validation_request_email
    PlanningApplicationMailer.validation_request_mail(
      @planning_application,
      @red_line_boundary_change_validation_request,
    ).deliver_now
  end
  
  def red_line_boundary_audit_item(validation_request)
    validation_request.reason
  end
end
