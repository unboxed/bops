class Api::V1::DescriptionChangeRequestsController < Api::V1::ApplicationController
  skip_before_action :verify_authenticity_token, only: :update
  before_action :check_token_and_set_application, only: :update, if: :json_request?

  def update
    @description_change_request = @planning_application.description_change_requests.where(id: params[:id]).first

    if @description_change_request.update(description_change_params)
      @description_change_request.update!(state: "closed")
      render json: { "message": "Change request updated" }, status: :ok
    else
      render json: { "message": "Unable to update request. Please ensure rejection_reason is present if approved is false." }, status: 400
    end
  end

private

  def description_change_params
    { approved: params[:data][:approved],
      rejection_reason: params[:data][:rejection_reason] }
  end

  def check_token_and_set_application
    @planning_application = current_local_authority.planning_applications.where(id: params[:planning_application_id]).first
    if params[:change_access_id] != @planning_application.change_access_id
      render json: {}, status: 401
    else
      @planning_application
    end
  end
end
