require "rails_helper"

RSpec.describe "API request to list change requests", type: :request, show_exceptions: true do
  let!(:api_user) { create :api_user }
  let!(:planning_application) { create(:planning_application, local_authority: @default_local_authority) }
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
    patch "/api/v1/planning_applications/#{planning_application.id}/other_change_validation_requests/#{other_change_validation_request.id}?change_access_id=#{planning_application.change_access_id}",
          params: valid_response,
          headers: { "CONTENT-TYPE": "application/json", "Authorization": "Bearer #{api_user.token}" }

    expect(response).to be_successful

    other_change_validation_request.reload
    planning_application.reload
    expect(other_change_validation_request.state).to eq("closed")
    expect(other_change_validation_request.response).to eq("I will send an extra payment")
    expect(Audit.all.last.activity_type).to eq("other_change_validation_request_received")
    expect(Audit.all.last.audit_comment).to eq({ response: "I will send an extra payment" }.to_json)
    expect(Audit.all.last.activity_information).to eq("1")
  end

  it "returns a 400 if the update is missing a response" do
    patch "/api/v1/planning_applications/#{planning_application.id}/other_change_validation_requests/#{other_change_validation_request.id}?change_access_id=#{planning_application.change_access_id}",
          params: missing_response,
          headers: { "CONTENT-TYPE": "application/json", "Authorization": "Bearer #{api_user.token}" }

    expect(response.status).to eq(400)
  end

  it "returns a 401 if API key is wrong" do
    patch "/api/v1/planning_applications/#{planning_application.id}/other_change_validation_requests/#{other_change_validation_request.id}?change_access_id=#{planning_application.change_access_id}",
          params: valid_response,
          headers: { "CONTENT-TYPE": "application/json", "Authorization": "Bearer BEAR_THE_BEARER" }

    expect(response.status).to eq(401)
  end

  it "returns a 401 if change_access_id is wrong" do
    patch "/api/v1/planning_applications/#{planning_application.id}/other_change_validation_requests/#{other_change_validation_request.id}?change_access_id=CHANGEISGOOD",
          params: valid_response,
          headers: { "CONTENT-TYPE": "application/json", "Authorization": "Bearer #{api_user.token}" }

    expect(response.status).to eq(401)
  end
end
