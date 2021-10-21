# frozen_string_literal: true

class DescriptionChangeValidationRequestsController < ValidationRequestsController
  before_action :set_planning_application, only: %i[new create show cancel]
  before_action :set_description_change_request, only: %i[show cancel auto_update_and_notify]

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
      audit("description_change_validation_request_sent", description_audit_item(@description_change_request, @planning_application),
            @description_change_request.sequence)
      redirect_to planning_application_path(@planning_application), notice: "Description change request successfully sent."
    else
      render :new
    end
  end

  def show; end

  def cancel
    @description_change_request.update!(state: "closed", approved: false, rejection_reason: "Request cancelled by planning officer.")
    flash[:notice] = "Description change request successfully cancelled."

    audit("description_change_request_cancelled", current_user.name,
          @description_change_request.sequence)
    redirect_to planning_application_path(@planning_application)
  end

  def auto_update_and_notify
    # 5 business days after creation of the description change, call this action
    @planning_application.update!(description: @description_change_request.proposed_description)
    @description_change_request.update!(state: "closed", approved: true)
    email_description_closure_notification(@description_change_request)
  end

  private

  def set_description_change_request
    @description_change_request = @planning_application.description_change_validation_requests.find(params[:id] ||= params[:description_change_validation_request_id])
  end

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
