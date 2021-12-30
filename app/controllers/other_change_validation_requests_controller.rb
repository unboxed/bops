# frozen_string_literal: true

class OtherChangeValidationRequestsController < ValidationRequestsController
  include ValidationRequests

  before_action :set_other_validation_request, only: %i[show edit update]

  def new
    @other_change_validation_request = @planning_application.other_change_validation_requests.new
  end

  def show; end

  def create
    @other_change_validation_request = @planning_application.other_change_validation_requests.new(other_change_validation_request_params)
    @other_change_validation_request.user = current_user

    if @other_change_validation_request.save
      email_and_timestamp(@other_change_validation_request) if @planning_application.invalidated?

      flash[:notice] = "Other validation change request successfully created."
      if @planning_application.invalidated?
        audit("other_change_validation_request_sent", audit_item(@other_change_validation_request),
              @other_change_validation_request.sequence)
      else
        audit("other_change_validation_request_added", audit_item(@other_change_validation_request),
              @other_change_validation_request.sequence)
      end
      redirect_to planning_application_validation_requests_path(@planning_application)
    else
      render :new
    end
  end

  def edit; end

  def update; end

  private

  def other_change_validation_request_params
    params.require(:other_change_validation_request).permit(:summary, :suggestion)
  end

  def audit_item(other_change_validation_request)
    { summary: other_change_validation_request.summary, suggestion: other_change_validation_request.suggestion }.to_json
  end

  def set_other_validation_request
    @other_change_validation_request = @planning_application.other_change_validation_requests.find(params[:id])
  end
end
