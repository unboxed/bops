class Api::V1::RedLineBoundaryChangeRequestsController < Api::V1::ApplicationController
  skip_before_action :verify_authenticity_token, only: :update
  before_action :check_token_and_set_application, only: :update

  def update
    @red_line_boundary_change_request = @planning_application.red_line_boundary_change_requests.find(params[:id])

    if @red_line_boundary_change_request.update(red_line_boundary_change_params)
      @red_line_boundary_change_request.update!(state: "closed")
      @planning_application.update!(boundary_geojson: @red_line_boundary_change_request.new_geojson) if @red_line_boundary_change_request.approved?

      audit("red_line_boundary_change_request_received", red_line_boundary_audit_item(@red_line_boundary_change_request),
            @red_line_boundary_change_request.sequence)

      render json: { "message": "Change request updated" }, status: :ok
    else
      render json: { "message": "Unable to update request. Please ensure rejection_reason is present if approved is false." }, status: :bad_request
    end
  end

private

  def red_line_boundary_change_params
    { approved: params[:data][:approved],
      rejection_reason: params[:data][:rejection_reason] }
  end

  def red_line_boundary_audit_item(change_request)
    if change_request.approved?
      { response: "approved" }.to_json
    else
      { response: "rejected", reason: change_request.rejection_reason }.to_json
    end
  end
end
