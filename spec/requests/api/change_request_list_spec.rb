# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API request to list change requests", type: :request, show_exceptions: true do
  let!(:api_user) { create :api_user }
  let!(:planning_application) { create(:planning_application, local_authority: @default_local_authority) }
  let!(:description_change_request) { create(:description_change_request, planning_application: planning_application) }
  let!(:document_change_request) { create(:document_change_request, planning_application: planning_application) }
  let!(:document_create_request) { create(:document_create_request, planning_application: planning_application) }

  it "lists the all description change requests that exist on the planning application" do
    get "/api/v1/planning_applications/#{planning_application.id}/change_requests?change_access_id=#{planning_application.change_access_id}", headers: { "CONTENT-TYPE": "application/json", "Authorization": "Bearer #{api_user.token}" }
    expect(response).to be_successful
    expect(json["data"]["description_change_requests"]).to eq([{
      "id" => description_change_request.id,
      "type" => "description_change_request",
      "state" => "open",
      "response_due" => description_change_request.response_due.to_s,
      "proposed_description" => description_change_request.proposed_description,
      "previous_description" => description_change_request.previous_description,
      "approved" => nil,
      "rejection_reason" => nil,
      "days_until_response_due" => description_change_request.days_until_response_due,
    }])
  end

  it "lists the all document change requests that exist on the planning application" do
    get "/api/v1/planning_applications/#{planning_application.id}/change_requests?change_access_id=#{planning_application.change_access_id}", headers: { "CONTENT-TYPE": "application/json", "Authorization": "Bearer #{api_user.token}" }
    expect(response).to be_successful
    expect(json["data"]["document_change_requests"].first).to include({
      "id" => document_change_request.id,
      "state" => "open",
      "response_due" => document_change_request.response_due.strftime("%Y-%m-%d"),
      "days_until_response_due" => document_change_request.days_until_response_due,
      "old_document" => {
        "name" => document_change_request.old_document.name.to_s,
        "invalid_document_reason" => nil,
      },
      "type" => "document_change_request",
    })
    expect(json["data"]["document_change_requests"].first["new_document"]["name"]).to eq("proposed-floorplan.png")
    expect(json["data"]["document_change_requests"].first["new_document"]["url"]).to be_a(String)
  end

  it "lists the all document create requests that exist on the planning application" do
    get "/api/v1/planning_applications/#{planning_application.id}/change_requests?change_access_id=#{planning_application.change_access_id}", headers: { "CONTENT-TYPE": "application/json", "Authorization": "Bearer #{api_user.token}" }
    expect(response).to be_successful
    expect(json["data"]["document_create_requests"].first).to include({
      "id" => document_create_request.id,
      "state" => "open",
      "response_due" => document_create_request.response_due.strftime("%Y-%m-%d"),
      "days_until_response_due" => document_create_request.days_until_response_due,
      "document_request_type" => document_create_request.document_request_type,
      "document_request_reason" => document_create_request.document_request_reason,
      "type" => "document_create_request",
    })
    expect(json["data"]["document_create_requests"].first["new_document"]["name"]).to eq("proposed-floorplan.png")
    expect(json["data"]["document_create_requests"].first["new_document"]["url"]).to be_a(String)
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
