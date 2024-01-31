# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API request to list validation requests", show_exceptions: true do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:api_user) { create(:api_user, local_authority: default_local_authority) }
  let!(:planning_application) { create(:planning_application, :invalidated, local_authority: default_local_authority) }
  let!(:description_change_validation_request) do
    create(:description_change_validation_request, planning_application:)
  end
  let!(:replacement_document_validation_request) do
    create(:replacement_document_validation_request, :with_response, planning_application:)
  end
  let!(:additional_document_validation_request) do
    create(:additional_document_validation_request, :with_documents, planning_application:)
  end

  it "lists the all description validation requests that exist on the planning application" do
    get "/api/v1/planning_applications/#{planning_application.id}/validation_requests?change_access_id=#{planning_application.change_access_id}",
      headers: {"CONTENT-TYPE": "application/json", Authorization: "Bearer #{api_user.token}"}
    expect(response).to be_successful
    expect(json["data"]["description_change_validation_requests"]).to eq([{
      "id" => description_change_validation_request.id,
      "type" => "description_change_validation_request",
      "state" => "open",
      "response_due" => description_change_validation_request.response_due.to_fs(:db),
      "proposed_description" => description_change_validation_request.proposed_description,
      "previous_description" => description_change_validation_request.previous_description,
      "approved" => nil,
      "rejection_reason" => nil,
      "days_until_response_due" => description_change_validation_request.days_until_response_due,
      "cancel_reason" => nil,
      "cancelled_at" => nil
    }])
  end

  it "lists the all document validation requests that exist on the planning application" do
    get "/api/v1/planning_applications/#{planning_application.id}/validation_requests?change_access_id=#{planning_application.change_access_id}",
      headers: {"CONTENT-TYPE": "application/json", Authorization: "Bearer #{api_user.token}"}
    expect(response).to be_successful
    expect(json["data"]["replacement_document_validation_requests"].first).to include({
      "id" => replacement_document_validation_request.id,
      "state" => "closed",
      "response_due" => replacement_document_validation_request.response_due.strftime("%Y-%m-%d"),
      "days_until_response_due" => replacement_document_validation_request.days_until_response_due,
      "old_document" => {
        "name" => replacement_document_validation_request.old_document.name.to_s,
        "invalid_document_reason" => "Document is invalid"
      },
      "type" => "replacement_document_validation_request"
    })
    expect(json["data"]["replacement_document_validation_requests"].first["new_document"]["name"]).to eq("proposed-floorplan.png")
    expect(json["data"]["replacement_document_validation_requests"].first["new_document"]["url"]).to be_a(String)
  end

  it "lists the all document create requests that exist on the planning application" do
    get "/api/v1/planning_applications/#{planning_application.id}/validation_requests?change_access_id=#{planning_application.change_access_id}",
      headers: {"CONTENT-TYPE": "application/json", Authorization: "Bearer #{api_user.token}"}
    expect(response).to be_successful
    expect(json["data"]["additional_document_validation_requests"].first).to include({
      "id" => additional_document_validation_request.id,
      "state" => "open",
      "response_due" => additional_document_validation_request.response_due.strftime("%Y-%m-%d"),
      "days_until_response_due" => additional_document_validation_request.days_until_response_due,
      "document_request_type" => additional_document_validation_request.document_request_type,
      "reason" => additional_document_validation_request.reason,
      "type" => "additional_document_validation_request"
    })

    expect(json["data"]["additional_document_validation_requests"].first["documents"][0]["name"]).to eq("proposed-floorplan.png")
    expect(json["data"]["additional_document_validation_requests"].first["documents"][0]["url"]).to be_a(String)
  end

  it "returns a 401 if API key is wrong" do
    get "/api/v1/planning_applications/#{planning_application.id}/validation_requests?change_access_id=#{planning_application.change_access_id}",
      headers: {"CONTENT-TYPE": "application/json", Authorization: "Bearer bipbopboop"}
    expect(response).to have_http_status(:unauthorized)
  end

  it "returns a 401 if change_access_id is wrong" do
    get "/api/v1/planning_applications/#{planning_application.id}/validation_requests?change_access_id=fffffff",
      headers: {"CONTENT-TYPE": "application/json", Authorization: "Bearer #{api_user.token}"}
    expect(response).to have_http_status(:unauthorized)
  end
end
