require "rails_helper"

RSpec.describe "API request to patch document validation requests", type: :request, show_exceptions: true do
  include ActionDispatch::TestProcess::FixtureFile

  let!(:api_user) { create :api_user }
  let!(:planning_application) { create(:planning_application, local_authority: @default_local_authority) }

  let!(:red_line_boundary_change_validation_request) do
    create(:red_line_boundary_change_validation_request,
           planning_application: planning_application)
  end

  approved_json = '{
    "data": {
      "approved": true
    }
  }'

  rejected_json = '{
    "data": {
      "approved": false,
      "rejection_reason": "The boundary is incorrect"
    }
  }'

  rejected_json_missing_reason = '{
    "data": {
      "approved": false
    }
  }'

  it "successfully updates the red line boundary validation request" do
    patch "/api/v1/planning_applications/#{planning_application.id}/red_line_boundary_change_validation_requests/#{red_line_boundary_change_validation_request.id}?change_access_id=#{planning_application.change_access_id}",
          params: approved_json,
          headers: { "CONTENT-TYPE": "application/json", "Authorization": "Bearer #{api_user.token}" }

    expect(response).to be_successful

    red_line_boundary_change_validation_request.reload
    planning_application.reload

    expect(red_line_boundary_change_validation_request.state).to eq("closed")
    expect(red_line_boundary_change_validation_request.approved).to eq(true)
    expect(red_line_boundary_change_validation_request.approved).to eq(true)
    expect(planning_application.boundary_geojson).to eq(red_line_boundary_change_validation_request.new_geojson)

    red_line_boundary_change_validation_request.reload
    planning_application.reload

    expect(Audit.all.last.activity_type).to eq("red_line_boundary_change_validation_request_received")
    expect(Audit.all.last.audit_comment).to eq({ response: "approved" }.to_json)
    expect(Audit.all.last.activity_information).to eq("1")
  end

  it "successfully accepts a rejection" do
    patch "/api/v1/planning_applications/#{planning_application.id}/red_line_boundary_change_validation_requests/#{red_line_boundary_change_validation_request.id}?change_access_id=#{planning_application.change_access_id}",
          params: rejected_json,
          headers: { "CONTENT-TYPE": "application/json", "Authorization": "Bearer #{api_user.token}" }

    expect(response).to be_successful

    red_line_boundary_change_validation_request.reload
    expect(red_line_boundary_change_validation_request.state).to eq("closed")
    expect(red_line_boundary_change_validation_request.approved).to eq(false)
    expect(red_line_boundary_change_validation_request.rejection_reason).to eq("The boundary is incorrect")
    expect(Audit.all.last.activity_type).to eq("red_line_boundary_change_validation_request_received")
    expect(Audit.all.last.audit_comment).to eq({ response: "rejected", reason: "The boundary is incorrect" }.to_json)
    expect(Audit.all.last.activity_information).to eq("1")
  end

  it "returns a 400 if params are missing" do
    patch "/api/v1/planning_applications/#{planning_application.id}/red_line_boundary_change_validation_requests/#{red_line_boundary_change_validation_request.id}?change_access_id=#{planning_application.change_access_id}",
          params: rejected_json_missing_reason,
          headers: { "CONTENT-TYPE": "application/json", "Authorization": "Bearer #{api_user.token}" }

    expect(response.status).to eq(400)
  end
end
