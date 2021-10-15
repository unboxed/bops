# frozen_string_literal: true

class DescriptionChangeValidationRequestsController < ValidationRequestsController
  before_action :set_planning_application, only: %i[new create]

  include ValidationRequests

  def new
    @description_change_request = @planning_application.description_change_validation_requests.new
  end

  def create
    @description_change_request = @planning_application.description_change_validation_requests.new(description_change_validation_request_params)
    @description_change_request.user = current_user
    @current_local_authority = current_local_authority

    if @description_change_request.save
      email_and_timestamp(@description_change_request)
      flash[:notice] = "Description change request successfully sent."
      audit("description_change_validation_request_sent", description_audit_item(@description_change_request, @planning_application),
            @description_change_request.sequence)
      redirect_to planning_application_path(@planning_application)
    else
      render :new
    end
  end

  private

  def description_change_validation_request_params
    params.require(:description_change_validation_request).permit(:proposed_description)
  end

  def set_planning_application
    @planning_application = PlanningApplication.find(params[:planning_application_id])
  end

  def description_audit_item(description_change_validation_request, planning_application)
    { previous: planning_application.description,
      proposed: description_change_validation_request.proposed_description }.to_json
  end
end
