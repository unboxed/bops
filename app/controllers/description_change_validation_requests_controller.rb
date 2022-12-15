# frozen_string_literal: true

class DescriptionChangeValidationRequestsController < ValidationRequestsController
  before_action :ensure_planning_application_is_not_closed_or_cancelled, only: %i[new create]
  before_action :set_description_change_request, only: %i[show cancel]

  def show; end

  def new
    @description_change_request = @planning_application.description_change_validation_requests.new
  end

  def create
    @description_change_request = @planning_application.description_change_validation_requests.new(description_change_validation_request_params)
    @description_change_request.user = current_user
    @current_local_authority = current_local_authority

    if @description_change_request.save
      redirect_to(after_save_path, notice: t(".success"))
    else
      render :new
    end
  end

  def cancel
    DescriptionChangeValidationRequest.transaction do
      @description_change_request.update!(cancel_reason: "Request cancelled by planning officer.")
      @description_change_request.cancel
      @description_change_request.audit_cancel!
    end

    redirect_to(after_save_path, notice: t(".success"))
  end

  private

  def after_save_path
    params.dig(:description_change_validation_request, :return_to) ||
      @planning_application
  end

  def set_description_change_request
    @description_change_request = @planning_application.description_change_validation_requests.find(params[:id] ||= params[:description_change_validation_request_id])
  end

  def description_change_validation_request_params
    params.require(:description_change_validation_request).permit(:proposed_description)
  end
end
