# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Replacement document validation requests API", type: :request, show_exceptions: true do
  let!(:api_user) { create(:api_user) }
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:planning_application) { create(:planning_application, local_authority: default_local_authority) }
  let!(:replacement_document_validation_request) do
    create(:replacement_document_validation_request, planning_application: planning_application)
  end
  let(:token) { "Bearer #{api_user.token}" }

  describe "#index" do
    let(:path) { "/api/v1/planning_applications/#{planning_application.id}/replacement_document_validation_requests" }
    let!(:replacement_document_validation_request2) do
      create(:replacement_document_validation_request, :closed, planning_application: planning_application)
    end
    let!(:replacement_document_validation_request3) do
      create(:replacement_document_validation_request, :cancelled, planning_application: planning_application)
    end

    context "when the request is successful" do
      it "retrieves all replacement document validation requests for a given planning application" do
        get "#{path}?change_access_id=#{planning_application.change_access_id}",
            headers: { "CONTENT-TYPE": "application/json", Authorization: token }

        expect(response).to be_successful
        expect(sort_by_id(json["data"])).to eq(
          [
            {
              "id" => replacement_document_validation_request.id,
              "state" => "open",
              "response_due" => replacement_document_validation_request.response_due.to_s(:db),
              "days_until_response_due" => 15,
              "cancel_reason" => nil,
              "cancelled_at" => nil,
              "old_document" => {
                "name" => "proposed-floorplan.png",
                "invalid_document_reason" => nil,
                "url" => json["data"][0]["old_document"]["url"]
              },
              "new_document" => {
                "name" => "proposed-floorplan.png",
                "url" => json["data"][0]["new_document"]["url"]
              }
            },
            {
              "id" => replacement_document_validation_request2.id,
              "state" => "closed",
              "response_due" => replacement_document_validation_request2.response_due.to_s(:db),
              "days_until_response_due" => 15,
              "cancel_reason" => nil,
              "cancelled_at" => nil,
              "old_document" => {
                "name" => "proposed-floorplan.png",
                "invalid_document_reason" => nil,
                "url" => json["data"][1]["old_document"]["url"]
              },
              "new_document" => {
                "name" => "proposed-floorplan.png",
                "url" => json["data"][1]["new_document"]["url"]
              }
            },
            {
              "id" => replacement_document_validation_request3.id,
              "state" => "cancelled",
              "response_due" => replacement_document_validation_request3.response_due.to_s(:db),
              "days_until_response_due" => 15,
              "cancel_reason" => "Made by mistake!",
              "cancelled_at" => json_time_format(replacement_document_validation_request3.cancelled_at),
              "old_document" => {
                "name" => "proposed-floorplan.png",
                "invalid_document_reason" => nil,
                "url" => json["data"][2]["old_document"]["url"]
              },
              "new_document" => {
                "name" => "proposed-floorplan.png",
                "url" => json["data"][2]["new_document"]["url"]
              }
            }
          ]
        )
      end
    end

    context "when the request is forbidden" do
      it_behaves_like "ApiRequest::Forbidden"
    end

    context "when the request is not found" do
      describe "when the planning request is not found" do
        let(:path) { "/api/v1/planning_applications/#{planning_application.id + 1}/replacement_document_validation_requests" }

        it_behaves_like "ApiRequest::NotFound", "planning_application"
      end
    end
  end

  describe "#show" do
    let(:path) do
      "/api/v1/planning_applications/#{planning_application.id}/replacement_document_validation_requests/#{replacement_document_validation_request.id}"
    end

    context "when the request is successful" do
      it "retrieves a replacement document validation request for a given planning application" do
        get "#{path}?change_access_id=#{planning_application.change_access_id}",
            headers: { "CONTENT-TYPE": "application/json", Authorization: token }

        expect(response).to be_successful
        expect(json).to eq(
          {
            "id" => replacement_document_validation_request.id,
            "state" => "open",
            "response_due" => replacement_document_validation_request.response_due.to_s(:db),
            "days_until_response_due" => 15,
            "cancel_reason" => nil,
            "cancelled_at" => nil,
            "old_document" => {
              "name" => "proposed-floorplan.png",
              "invalid_document_reason" => nil,
              "url" => json["old_document"]["url"]
            },
            "new_document" => {
              "name" => "proposed-floorplan.png",
              "url" => json["new_document"]["url"]
            }
          }
        )
      end
    end

    context "when the request is forbidden" do
      it_behaves_like "ApiRequest::Forbidden"
    end

    context "when the request is not found" do
      describe "when the planning request is not found" do
        let(:path) do
          "/api/v1/planning_applications/#{planning_application.id + 1}/replacement_document_validation_requests/#{replacement_document_validation_request.id}"
        end

        it_behaves_like "ApiRequest::NotFound", "planning_application"
      end

      describe "when the replacement document request is not found" do
        let(:path) do
          "/api/v1/planning_applications/#{planning_application.id}/replacement_document_validation_requests/#{replacement_document_validation_request.id + 1}"
        end

        it_behaves_like "ApiRequest::NotFound", "replacement_document_validation_request"
      end
    end
  end
end
