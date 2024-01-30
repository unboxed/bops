# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API request to list change requests", show_exceptions: true do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:api_user) { create(:api_user, local_authority: default_local_authority) }

  let(:path) do
    "/api/v1/planning_applications/#{planning_application.id}/fee_change_validation_requests/#{fee_change_validation_request.id}"
  end

  let(:params) do
    {
      change_access_id: planning_application.change_access_id,
      data: {response: "I will send an extra payment"}
    }
  end

  let(:headers) do
    {Authorization: "Bearer #{api_user.token}"}
  end

  let(:user) { create(:user, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(
      :planning_application,
      :invalidated,
      user:,
      local_authority: default_local_authority
    )
  end

  let!(:fee_change_validation_request) do
    create(:fee_change_validation_request,
      planning_application:)
  end

  valid_response = '{
    "data": {
      "response": "I will send an extra payment"
    }
  }'

  it "successfully accepts a response" do
    patch(path, params:, headers:)

    expect(response).to be_successful

    fee_change_validation_request.reload
    planning_application.reload
    expect(fee_change_validation_request.state).to eq("closed")
    expect(fee_change_validation_request.response).to eq("I will send an extra payment")
  end

  it "creates audit associated with API user" do
    patch(path, params:, headers:)

    expect(planning_application.audits.reload.last).to have_attributes(
      activity_type: "fee_change_validation_request_received",
      audit_comment: {response: "I will send an extra payment"}.to_json,
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

  it "returns a 401 if API key is wrong" do
    patch "/api/v1/planning_applications/#{planning_application.id}/fee_change_validation_requests/#{fee_change_validation_request.id}?change_access_id=#{planning_application.change_access_id}",
      params: valid_response,
      headers: {"CONTENT-TYPE": "application/json", Authorization: "Bearer BEAR_THE_BEARER"}

    expect(response).to have_http_status(:unauthorized)
  end

  it "returns a 401 if change_access_id is wrong" do
    patch "/api/v1/planning_applications/#{planning_application.id}/fee_change_validation_requests/#{fee_change_validation_request.id}?change_access_id=CHANGEISGOOD",
      params: valid_response,
      headers: {"CONTENT-TYPE": "application/json", Authorization: "Bearer #{api_user.token}"}

    expect(response).to have_http_status(:unauthorized)
  end
end
