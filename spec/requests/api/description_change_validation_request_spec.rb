# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Description change validation requests API", type: :request, show_exceptions: true do
  let!(:api_user) { create(:api_user) }
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:planning_application) { create(:planning_application, local_authority: default_local_authority) }
  let!(:description_change_validation_request) do
    create(:description_change_validation_request, planning_application: planning_application)
  end
  let(:token) { "Bearer #{api_user.token}" }

  describe "#index" do
    let(:path) { "/api/v1/planning_applications/#{planning_application.id}/description_change_validation_requests" }

    context "when the request is successful" do
      it "retrieves all description change validation requests for a given planning application" do
        get "#{path}?change_access_id=#{planning_application.change_access_id}",
            headers: { "CONTENT-TYPE": "application/json", Authorization: token }

        expect(response).to be_successful
        expect(sort_by_id(json["data"])).to eq(
          [
            {
              "id" => description_change_validation_request.id,
              "state" => "open",
              "response_due" => description_change_validation_request.response_due.to_s(:db),
              "proposed_description" => "New description",
              "previous_description" => description_change_validation_request.previous_description,
              "rejection_reason" => nil,
              "approved" => nil,
              "days_until_response_due" => 15,
              "cancel_reason" => nil,
              "cancelled_at" => nil
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
        let(:path) { "/api/v1/planning_applications/#{planning_application.id + 1}/description_change_validation_requests" }

        it_behaves_like "ApiRequest::NotFound", "planning_application"
      end
    end
  end

  describe "#show" do
    let(:path) do
      "/api/v1/planning_applications/#{planning_application.id}/description_change_validation_requests/#{description_change_validation_request.id}"
    end

    context "when the request is successful" do
      it "retrieves an description change validation request for a given planning application" do
        get "#{path}?change_access_id=#{planning_application.change_access_id}",
            headers: { "CONTENT-TYPE": "application/json", Authorization: token }

        expect(response).to be_successful
        expect(json).to eq(
          {
            "id" => description_change_validation_request.id,
            "state" => "open",
            "response_due" => description_change_validation_request.response_due.to_s(:db),
            "proposed_description" => "New description",
            "previous_description" => description_change_validation_request.previous_description,
            "rejection_reason" => nil,
            "approved" => nil,
            "days_until_response_due" => 15,
            "cancel_reason" => nil,
            "cancelled_at" => nil
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
          "/api/v1/planning_applications/#{planning_application.id + 1}/description_change_validation_requests/#{description_change_validation_request.id}"
        end

        it_behaves_like "ApiRequest::NotFound", "planning_application"
      end

      describe "when the description change validation request is not found" do
        let(:path) do
          "/api/v1/planning_applications/#{planning_application.id}/description_change_validation_requests/#{description_change_validation_request.id + 1}"
        end

        it_behaves_like "ApiRequest::NotFound", "description_change_validation_request"
      end
    end
  end
end
