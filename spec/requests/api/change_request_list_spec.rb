# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API request to list change requests", type: :request, show_exceptions: true do
  let!(:api_user) { create :api_user }
  let!(:planning_application) { create(:planning_application, local_authority: @default_local_authority) }
  let!(:description_change_request) { create(:description_change_request, planning_application: planning_application) }

  it "lists the description_change_requests that exist on the planning application" do
    get "/api/v1/planning_applications/#{planning_application.id}/change_requests?change_access_id=#{planning_application.change_access_id}", headers: { "CONTENT-TYPE": "application/json", "Authorization": "Bearer #{api_user.token}" }
    expect(response).to be_successful
    expect(json["data"]).to eq([{
      "id" => description_change_request.id,
      "type" => "description_change_request",
      "state" => "open",
      "response_due" => description_change_request.response_due.to_s,
      "proposed_description" => description_change_request.proposed_description,
      "approved" => nil,
      "rejection_reason" => nil,
    }])
  end

  it "returns a 401 if API key is wrong" do
    get "/api/v1/planning_applications/#{planning_application.id}/change_requests?change_access_id=#{planning_application.change_access_id}", headers: { "CONTENT-TYPE": "application/json", "Authorization": "Bearer bipbopboop" }
    expect(response.status).to eq(401)
  end

  it "returns a 401 if change_access_id is wrong" do
    get "/api/v1/planning_applications/#{planning_application.id}/change_requests?change_access_id=fffffff", headers: { "CONTENT-TYPE": "application/json", "Authorization": "Bearer #{api_user.token}" }
    expect(response.status).to eq(401)
  end
end
