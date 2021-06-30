class Api::V1::DescriptionChangeRequestsController < Api::V1::ApplicationController
  skip_before_action :verify_authenticity_token, only: :update
  before_action :check_token_and_set_application, only: :update

  def update
    @description_change_request = @planning_application.description_change_requests.where(id: params[:id]).first

    if @description_change_request.update(description_change_params)
      @description_change_request.update!(state: "closed")
      @planning_application.update!(description: @description_change_request.proposed_description) if @description_change_request.approved?

      audit("description_change_request_received", description_audit_item(@description_change_request),
            @description_change_request.sequence, current_api_user)

      render json: { "message": "Change request updated" }, status: :ok
    else
      render json: { "message": "Unable to update request. Please ensure rejection_reason is present if approved is false." }, status: :bad_request
    end
  end

private

  def description_change_params
    { approved: params[:data][:approved],
      rejection_reason: params[:data][:rejection_reason] }
  end

  def description_audit_item(change_request)
    if change_request.approved?
      { response: "approved" }.to_json
    else
      { response: "rejected", reason: change_request.rejection_reason }.to_json
    end
  end
end
