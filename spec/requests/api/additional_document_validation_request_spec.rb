# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Additional document validation requests API" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:api_user) { create(:api_user, :validation_requests_rw, local_authority: default_local_authority) }
  let!(:planning_application) { create(:planning_application, :invalidated, local_authority: default_local_authority) }
  let!(:additional_document_validation_request) do
    travel_to(DateTime.new(2023, 12, 15)) { create(:additional_document_validation_request, planning_application:) }
  end
  let(:token) { "Bearer #{api_user.token}" }

  describe "#index" do
    let(:path) { "/api/v1/planning_applications/#{planning_application.reference}/additional_document_validation_requests" }
    let!(:additional_document_validation_request2) do
      travel_to(DateTime.new(2023, 12, 15)) { create(:additional_document_validation_request, :closed, :with_documents, planning_application:) }
    end
    let!(:additional_document_validation_request3) do
      travel_to(DateTime.new(2023, 12, 15)) { create(:additional_document_validation_request, :cancelled, planning_application:) }
    end

    context "when the request is successful" do
      before do
        travel_to(DateTime.new(2023, 12, 15))
      end

      it "retrieves all additional document validation requests for a given planning application" do
        get "#{path}?change_access_id=#{planning_application.change_access_id}",
          headers: {"CONTENT-TYPE": "application/json", Authorization: token}

        expect(response).to be_successful
        expect(sort_by_id(json["data"])).to eq(
          [
            {
              "id" => additional_document_validation_request.id,
              "state" => "open",
              "response_due" => additional_document_validation_request.response_due.to_fs(:db),
              "days_until_response_due" => 15,
              "document_request_type" => "Floor plan",
              "reason" => "Missing floor plan",
              "cancel_reason" => nil,
              "cancelled_at" => nil,
              "documents" => [],
              "post_validation" => false
            },
            {
              "id" => additional_document_validation_request2.id,
              "state" => "closed",
              "response_due" => additional_document_validation_request2.response_due.to_fs(:db),
              "days_until_response_due" => 15,
              "document_request_type" => "Floor plan",
              "reason" => "Missing floor plan",
              "cancel_reason" => nil,
              "cancelled_at" => nil,
              "documents" => [
                {
                  "name" => "proposed-floorplan.png",
                  "url" => json["data"][1]["documents"][0]["url"]
                }
              ],
              "post_validation" => false
            },
            {
              "id" => additional_document_validation_request3.id,
              "state" => "cancelled",
              "response_due" => additional_document_validation_request3.response_due.to_fs(:db),
              "days_until_response_due" => 15,
              "document_request_type" => "Floor plan",
              "reason" => "Missing floor plan",
              "cancel_reason" => "Made by mistake!",
              "cancelled_at" => json_time_format(additional_document_validation_request3.cancelled_at),
              "documents" => [],
              "post_validation" => false
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
        let(:path) { "/api/v1/planning_applications/#{planning_application.id + 1}/additional_document_validation_requests" }

        it_behaves_like "ApiRequest::NotFound", "planning_application"
      end
    end
  end

  describe "#show" do
    let(:path) do
      "/api/v1/planning_applications/#{planning_application.reference}/additional_document_validation_requests/#{additional_document_validation_request.id}"
    end

    context "when the request is successful" do
      before do
        travel_to(DateTime.new(2023, 12, 15))
      end

      it "retrieves a additional document validation request for a given planning application" do
        get "#{path}?change_access_id=#{planning_application.change_access_id}",
          headers: {"CONTENT-TYPE": "application/json", Authorization: token}

        expect(response).to be_successful
        expect(json).to eq(
          {
            "id" => additional_document_validation_request.id,
            "state" => "open",
            "response_due" => additional_document_validation_request.response_due.to_fs(:db),
            "days_until_response_due" => 15,
            "document_request_type" => "Floor plan",
            "reason" => "Missing floor plan",
            "cancel_reason" => nil,
            "cancelled_at" => nil,
            "documents" => [],
            "post_validation" => false
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
          "/api/v1/planning_applications/#{planning_application.id + 1}/additional_document_validation_requests/#{additional_document_validation_request.id}"
        end

        it_behaves_like "ApiRequest::NotFound", "planning_application"
      end

      describe "when the additional document request is not found" do
        let(:path) do
          "/api/v1/planning_applications/#{planning_application.reference}/additional_document_validation_requests/#{additional_document_validation_request.id + 1}"
        end

        it_behaves_like "ApiRequest::NotFound", "additional_document_validation_request"
      end
    end
  end
end
