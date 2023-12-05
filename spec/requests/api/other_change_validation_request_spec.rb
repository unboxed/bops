# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Other change validation requests API", show_exceptions: true do
  let!(:api_user) { create(:api_user) }
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:planning_application) { create(:planning_application, :invalidated, local_authority: default_local_authority) }
  let!(:other_change_validation_request) do
    create(:other_change_validation_request, planning_application:)
  end
  let(:token) { "Bearer #{api_user.token}" }

  describe "#index" do
    let(:path) { "/api/v1/planning_applications/#{planning_application.id}/other_change_validation_requests" }
    let!(:other_change_validation_request2) do
      create(:other_change_validation_request, :closed, planning_application:)
    end
    let!(:other_change_validation_request3) do
      create(:other_change_validation_request, :cancelled, planning_application:)
    end

    context "when the request is successful" do
      it "retrieves all other change validation requests for a given planning application" do
        get "#{path}?change_access_id=#{planning_application.change_access_id}",
          headers: {"CONTENT-TYPE": "application/json", Authorization: token}

        expect(response).to be_successful
        expect(sort_by_id(json["data"])).to eq(
          [
            {
              "id" => other_change_validation_request.id,
              "state" => "open",
              "response_due" => other_change_validation_request.response_due.to_fs(:db),
              "response" => nil,
              "reason" => "Incorrect fee",
              "suggestion" => "You need to pay a different fee",
              "days_until_response_due" => 15,
              "cancel_reason" => nil,
              "cancelled_at" => nil
            },
            {
              "id" => other_change_validation_request2.id,
              "state" => "closed",
              "response_due" => other_change_validation_request.response_due.to_fs(:db),
              "response" => "Some response",
              "reason" => "Incorrect fee",
              "suggestion" => "You need to pay a different fee",
              "days_until_response_due" => 15,
              "cancel_reason" => nil,
              "cancelled_at" => nil
            },
            {
              "id" => other_change_validation_request3.id,
              "state" => "cancelled",
              "response_due" => other_change_validation_request.response_due.to_fs(:db),
              "response" => nil,
              "reason" => "Incorrect fee",
              "suggestion" => "You need to pay a different fee",
              "days_until_response_due" => 15,
              "cancel_reason" => "Made by mistake!",
              "cancelled_at" => json_time_format(other_change_validation_request3.cancelled_at)
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
        let(:path) { "/api/v1/planning_applications/#{planning_application.id + 1}/other_change_validation_requests" }

        it_behaves_like "ApiRequest::NotFound", "planning_application"
      end
    end
  end

  describe "#show" do
    let(:path) do
      "/api/v1/planning_applications/#{planning_application.id}/other_change_validation_requests/#{other_change_validation_request.id}"
    end

    context "when the request is successful" do
      it "retrieves an other change validation request for a given planning application" do
        get "#{path}?change_access_id=#{planning_application.change_access_id}",
          headers: {"CONTENT-TYPE": "application/json", Authorization: token}

        expect(response).to be_successful
        expect(json).to eq(
          {
            "id" => other_change_validation_request.id,
            "state" => "open",
            "response_due" => other_change_validation_request.response_due.to_fs(:db),
            "response" => nil,
            "reason" => "Incorrect fee",
            "suggestion" => "You need to pay a different fee",
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
          "/api/v1/planning_applications/#{planning_application.id + 1}/other_change_validation_requests/#{other_change_validation_request.id}"
        end

        it_behaves_like "ApiRequest::NotFound", "planning_application"
      end

      describe "when the other change validation request is not found" do
        let(:path) do
          "/api/v1/planning_applications/#{planning_application.id}/other_change_validation_requests/#{other_change_validation_request.id + 1}"
        end

        it_behaves_like "ApiRequest::NotFound", "other_change_validation_request"
      end
    end
  end
end
