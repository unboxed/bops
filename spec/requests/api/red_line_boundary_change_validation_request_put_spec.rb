# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API request to patch document validation requests", show_exceptions: true do
  include ActionDispatch::TestProcess::FixtureFile
  let!(:default_local_authority) { create(:local_authority, :default) }

  let(:path) do
    "/api/v1/planning_applications/#{planning_application.id}/red_line_boundary_change_validation_requests/#{red_line_boundary_change_validation_request.id}"
  end

  let(:params) do
    {
      change_access_id: planning_application.change_access_id,
      data: {applicant_approved: true}
    }
  end

  let(:headers) do
    {Authorization: "Bearer #{api_user.token}"}
  end

  let!(:api_user) { create(:api_user) }
  let(:user) { create(:user) }

  let!(:planning_application) do
    create(
      :planning_application,
      :invalidated,
      user:,
      local_authority: default_local_authority
    )
  end

  let!(:red_line_boundary_change_validation_request) do
    create(:red_line_boundary_change_validation_request,
      planning_application:)
  end

  rejected_json = '{
    "data": {
      "applicant_approved": false,
      "applicant_rejection_reason": "The boundary is incorrect"
    }
  }'

  rejected_json_missing_reason = '{
    "data": {
      "applicant_approved": false
    }
  }'

  it "successfully updates the red line boundary validation request" do
    patch(path, params:, headers:)

    expect(response).to be_successful

    red_line_boundary_change_validation_request.reload
    planning_application.reload

    expect(red_line_boundary_change_validation_request.state).to eq("closed")
    expect(red_line_boundary_change_validation_request.applicant_approved).to be(true)
    expect(red_line_boundary_change_validation_request.applicant_approved).to be(true)
    expect(planning_application.boundary_geojson).to eq(red_line_boundary_change_validation_request.new_geojson)
  end

  it "creates audit associated with API user" do
    patch(path, params:, headers:)

    expect(planning_application.audits.reload.last).to have_attributes(
      activity_type: "red_line_boundary_change_validation_request_received",
      audit_comment: {applicant_response: "approved"}.to_json,
      activity_information: "1",
      api_user:
    )
  end

  it "sends notification to assigned user" do
    expect { patch(path, params:, headers:) }
      .to have_enqueued_job
      .on_queue("low_priority")
      .with(
        "UserMailer",
        "update_notification_mail",
        "deliver_now",
        args: [planning_application, user.email]
      )
  end

  it "successfully accepts a rejection" do
    patch "/api/v1/planning_applications/#{planning_application.id}/red_line_boundary_change_validation_requests/#{red_line_boundary_change_validation_request.id}?change_access_id=#{planning_application.change_access_id}",
      params: rejected_json,
      headers: {"CONTENT-TYPE": "application/json", Authorization: "Bearer #{api_user.token}"}

    expect(response).to be_successful

    red_line_boundary_change_validation_request.reload
    expect(red_line_boundary_change_validation_request.state).to eq("closed")
    expect(red_line_boundary_change_validation_request.applicant_approved).to be(false)
    expect(red_line_boundary_change_validation_request.applicant_rejection_reason).to eq("The boundary is incorrect")
    expect(Audit.all.last.activity_type).to eq("red_line_boundary_change_validation_request_received")
    expect(Audit.all.last.audit_comment).to eq({applicant_response: "rejected", reason: "The boundary is incorrect"}.to_json)
    expect(Audit.all.last.activity_information).to eq("1")
  end

  it "returns a 400 if params are missing" do
    patch "/api/v1/planning_applications/#{planning_application.id}/red_line_boundary_change_validation_requests/#{red_line_boundary_change_validation_request.id}?change_access_id=#{planning_application.change_access_id}",
      params: rejected_json_missing_reason,
      headers: {"CONTENT-TYPE": "application/json", Authorization: "Bearer #{api_user.token}"}

    expect(response).to have_http_status(:bad_request)
  end
end
