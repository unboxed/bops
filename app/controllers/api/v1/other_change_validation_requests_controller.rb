class Api::V1::OtherChangeValidationRequestsController < Api::V1::ApplicationController
  skip_before_action :verify_authenticity_token, only: :update
  before_action :check_token_and_set_application, only: :update

  def update
    @other_change_validation_request = @planning_application.other_change_validation_requests.where(id: params[:id]).first

    if params[:data][:response].present? && @other_change_validation_request.update(response: params[:data][:response])
      @other_change_validation_request.update!(state: "closed")

      audit("other_change_validation_request_received", audit_item(@other_change_validation_request),
            @other_change_validation_request.sequence)

      render json: { "message": "Change request updated" }, status: :ok
    else
      render json: { "message": "Unable to update request. Please ensure response is present" }, status: :bad_request
    end
  end

private

  def audit_item(change_request)
    { response: change_request.response }.to_json
  end
end
