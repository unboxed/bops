class DescriptionChangeValidationRequestsController < ApplicationController
  before_action :set_planning_application, only: %i[new create]

  def new
    @description_change_validation_request = @planning_application.description_change_validation_requests.new
  end

  def create
    @description_change_validation_request = @planning_application.description_change_validation_requests.new(description_change_validation_request_params)
    @description_change_validation_request.user = current_user
    @current_local_authority = current_local_authority

    if @description_change_validation_request.save
      send_validation_request_email
      flash[:notice] = "Validation request for description successfully sent."
      audit("description_change_validation_request_sent", description_audit_item(@description_change_validation_request, @planning_application),
            @description_change_validation_request.sequence)
      redirect_to planning_application_validation_requests_path(@planning_application)
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

  def send_validation_request_email
    PlanningApplicationMailer.validation_request_mail(
      @planning_application,
      @description_change_validation_request,
    ).deliver_now
  end

  def description_audit_item(description_change_validation_request, planning_application)
    { previous: planning_application.description, proposed: description_change_validation_request.proposed_description }.to_json
  end
end
