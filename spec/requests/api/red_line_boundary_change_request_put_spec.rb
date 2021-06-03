require "rails_helper"

RSpec.describe "API request to patch document change requests", type: :request, show_exceptions: true do
  include ActionDispatch::TestProcess::FixtureFile

  let!(:api_user) { create :api_user }
  let!(:planning_application) { create(:planning_application, local_authority: @default_local_authority) }

  let!(:red_line_boundary_change_request) do
    create(:red_line_boundary_change_request,
           planning_application: planning_application)
  end

  approved_json = '{
    "data": {
      "approved": true
    }
  }'

  rejected_json_missing_reason = '{
    "data": {
      "approved": false,
      "rejection_reason": ""
    }
  }'

  it "successfully updates the red line boundary change request" do
    patch "/api/v1/planning_applications/#{planning_application.id}/red_line_boundary_change_requests/#{red_line_boundary_change_request.id}?change_access_id=#{planning_application.change_access_id}",
          params: approved_json,
          headers: { "CONTENT-TYPE": "application/json", "Authorization": "Bearer #{api_user.token}" }

    expect(response).to be_successful

    red_line_boundary_change_request.reload
    planning_application.reload

    expect(red_line_boundary_change_request.state).to eq("closed")
    expect(red_line_boundary_change_request.approved).to eq(true)
    expect(red_line_boundary_change_request.approved).to eq(true)
    expect(planning_application.boundary_geojson).to eq(red_line_boundary_change_request.new_geojson)

    red_line_boundary_change_request.reload
    planning_application.reload

  end

  it "returns a 400 if params are missing" do
    patch "/api/v1/planning_applications/#{planning_application.id}/red_line_boundary_change_requests/#{red_line_boundary_change_request.id}?change_access_id=#{planning_application.change_access_id}",
          params: rejected_json_missing_reason,
          headers: { "CONTENT-TYPE": "application/json", "Authorization": "Bearer #{api_user.token}" }

    expect(response.status).to eq(400)
  end
end
