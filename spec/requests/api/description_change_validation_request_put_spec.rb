# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API request to list validation requests", show_exceptions: true do
  let!(:api_user) { create(:api_user) }

  let(:path) do
    "/api/v1/planning_applications/#{planning_application.id}/description_change_validation_requests/#{description_change_validation_request.id}"
  end

  let(:params) do
    {
      change_access_id: planning_application.change_access_id,
      data: { approved: true }
    }
  end

  let(:headers) do
    { Authorization: "Bearer #{api_user.token}" }
  end

  let!(:default_local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user) }

  let!(:planning_application) do
    create(
      :planning_application,
      user:,
      local_authority: default_local_authority
    )
  end

  let!(:description_change_validation_request) do
    create(:description_change_validation_request,
           planning_application:,
           proposed_description: "new roof")
  end

  approved_json = '{
    "data": {
      "approved": true
    }
  }'

  rejected_json = '{
    "data": {
      "approved": false,
      "rejection_reason": "The description is unclear"
    }
  }'

  rejected_json_missing_reason = '{
    "data": {
      "approved": false,
      "rejection_reason": ""
    }
  }'

  it "successfully accepts an approval" do
    patch(path, params:, headers:)

    expect(response).to be_successful

    description_change_validation_request.reload
    planning_application.reload
    expect(description_change_validation_request.state).to eq("closed")
    expect(description_change_validation_request.approved).to be(true)
    expect(description_change_validation_request.approved).to be(true)
    expect(planning_application.description).to eq("new roof")
  end

  it "sends notification to assigned user" do
    expect { patch(path, params:, headers:) }
      .to have_enqueued_job
      .on_queue("default")
      .with(
        "UserMailer",
        "update_notification_mail",
        "deliver_now",
        args: [planning_application, user.email]
      )
  end

  it "creates audit associated with API user" do
    patch(path, params:, headers:)

    expect(planning_application.audits.reload.last).to have_attributes(
      activity_type: "description_change_validation_request_received",
      audit_comment: { response: "approved" }.to_json,
      activity_information: "1",
      api_user:
    )
  end

  it "successfully accepts a rejection" do
    patch "/api/v1/planning_applications/#{planning_application.id}/description_change_validation_requests/#{description_change_validation_request.id}?change_access_id=#{planning_application.change_access_id}",
          params: rejected_json,
          headers: { "CONTENT-TYPE": "application/json", Authorization: "Bearer #{api_user.token}" }

    expect(response).to be_successful

    description_change_validation_request.reload
    expect(description_change_validation_request.state).to eq("closed")
    expect(description_change_validation_request.approved).to be(false)
    expect(description_change_validation_request.rejection_reason).to eq("The description is unclear")
    expect(Audit.all.last.activity_type).to eq("description_change_validation_request_received")
    expect(Audit.all.last.audit_comment).to eq({ response: "rejected", reason: "The description is unclear" }.to_json)
    expect(Audit.all.last.activity_information).to eq("1")
  end

  it "returns a 400 if the rejection is missing a rejection reason" do
    patch "/api/v1/planning_applications/#{planning_application.id}/description_change_validation_requests/#{description_change_validation_request.id}?change_access_id=#{planning_application.change_access_id}",
          params: rejected_json_missing_reason,
          headers: { "CONTENT-TYPE": "application/json", Authorization: "Bearer #{api_user.token}" }

    expect(response).to have_http_status(:bad_request)
  end

  it "returns a 401 if API key is wrong" do
    patch "/api/v1/planning_applications/#{planning_application.id}/description_change_validation_requests/#{description_change_validation_request.id}?change_access_id=#{planning_application.change_access_id}",
          params: approved_json,
          headers: { "CONTENT-TYPE": "application/json", Authorization: "Bearer BEAR_THE_BEARER" }

    expect(response).to have_http_status(:unauthorized)
  end

  it "returns a 401 if change_access_id is wrong" do
    patch "/api/v1/planning_applications/#{planning_application.id}/description_change_validation_requests/#{description_change_validation_request.id}?change_access_id=CHANGEISGOOD",
          params: approved_json,
          headers: { "CONTENT-TYPE": "application/json", Authorization: "Bearer #{api_user.token}" }

    expect(response).to have_http_status(:unauthorized)
  end
end
