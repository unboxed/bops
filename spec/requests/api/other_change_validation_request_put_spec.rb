# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API request to list change requests", show_exceptions: true do
  let!(:api_user) { create(:api_user) }

  let(:path) do
    "/api/v1/planning_applications/#{planning_application.id}/other_change_validation_requests/#{other_change_validation_request.id}"
  end

  let(:params) do
    {
      change_access_id: planning_application.change_access_id,
      data: { response: "I will send an extra payment" }
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
      :invalidated,
      user: user,
      local_authority: default_local_authority
    )
  end

  let!(:other_change_validation_request) do
    create(:other_change_validation_request,
           planning_application: planning_application)
  end

  valid_response = '{
    "data": {
      "response": "I will send an extra payment"
    }
  }'

  missing_response = '{
    "data": {
      "response": ""
    }
  }'

  it "successfully accepts a response" do
    patch(path, params: params, headers: headers)

    expect(response).to be_successful

    other_change_validation_request.reload
    planning_application.reload
    expect(other_change_validation_request.state).to eq("closed")
    expect(other_change_validation_request.response).to eq("I will send an extra payment")
  end

  it "creates audit associated with API user" do
    patch(path, params: params, headers: headers)

    expect(planning_application.audits.reload.last).to have_attributes(
      activity_type: "other_change_validation_request_received",
      audit_comment: { response: "I will send an extra payment" }.to_json,
      activity_information: "1",
      api_user: api_user
    )
  end

  it "sends notification to assigned user" do
    expect { patch(path, params: params, headers: headers) }
      .to have_enqueued_job
      .on_queue("default")
      .with(
        "UserMailer",
        "update_notification_mail",
        "deliver_now",
        args: [planning_application, user.email]
      )
  end

  it "returns a 400 if the update is missing a response" do
    patch "/api/v1/planning_applications/#{planning_application.id}/other_change_validation_requests/#{other_change_validation_request.id}?change_access_id=#{planning_application.change_access_id}",
          params: missing_response,
          headers: { "CONTENT-TYPE": "application/json", Authorization: "Bearer #{api_user.token}" }

    expect(response).to have_http_status(:bad_request)
  end

  it "returns a 401 if API key is wrong" do
    patch "/api/v1/planning_applications/#{planning_application.id}/other_change_validation_requests/#{other_change_validation_request.id}?change_access_id=#{planning_application.change_access_id}",
          params: valid_response,
          headers: { "CONTENT-TYPE": "application/json", Authorization: "Bearer BEAR_THE_BEARER" }

    expect(response).to have_http_status(:unauthorized)
  end

  it "returns a 401 if change_access_id is wrong" do
    patch "/api/v1/planning_applications/#{planning_application.id}/other_change_validation_requests/#{other_change_validation_request.id}?change_access_id=CHANGEISGOOD",
          params: valid_response,
          headers: { "CONTENT-TYPE": "application/json", Authorization: "Bearer #{api_user.token}" }

    expect(response).to have_http_status(:unauthorized)
  end
end
