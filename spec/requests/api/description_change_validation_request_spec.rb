# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Description change validation requests API", show_exceptions: true do
  let(:api_user) { create(:api_user) }
  let(:default_local_authority) { create(:local_authority, :default) }

  let(:planning_application) do
    create(
      :planning_application,
      local_authority: default_local_authority,
      description: "Current description"
    )
  end

  let!(:description_change_validation_request) do
    create(
      :description_change_validation_request,
      planning_application: planning_application,
      created_at: DateTime.new(2022, 6, 20),
      proposed_description: "New description"
    )
  end

  let(:token) { "Bearer #{api_user.token}" }

  describe "#index" do
    let(:path) do
      api_v1_planning_application_description_change_validation_requests_path(
        planning_application
      )
    end

    context "when the request is valid" do
      it "succeeds" do
        get(
          path,
          params: { change_access_id: planning_application.change_access_id },
          headers: { "CONTENT-TYPE": "application/json", Authorization: token }
        )

        expect(response).to be_successful
      end

      it "retrieves all description change validation requests for a given planning application" do
        travel_to(DateTime.new(2022, 6, 20)) do
          get(
            path,
            params: { change_access_id: planning_application.change_access_id },
            headers: { "CONTENT-TYPE": "application/json", Authorization: token }
          )

          expect(json["data"]).to contain_exactly(
            {
              "id" => description_change_validation_request.id,
              "state" => "open",
              "response_due" => "2022-06-27",
              "proposed_description" => "New description",
              "previous_description" => "Current description",
              "rejection_reason" => nil,
              "approved" => nil,
              "days_until_response_due" => 5,
              "cancel_reason" => nil,
              "cancelled_at" => nil
            }
          )
        end
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
      api_v1_planning_application_description_change_validation_request_path(
        planning_application,
        description_change_validation_request
      )
    end

    context "when request is valid" do
      it "is successful" do
        get(
          path,
          params: { change_access_id: planning_application.change_access_id },
          headers: { "CONTENT-TYPE": "application/json", Authorization: token }
        )

        expect(response).to be_successful
      end

      it "retrieves an description change validation request for a given planning application" do
        travel_to(DateTime.new(2022, 6, 20)) do
          get(
            path,
            params: { change_access_id: planning_application.change_access_id },
            headers: { "CONTENT-TYPE": "application/json", Authorization: token }
          )

          expect(json).to eq(
            {
              "id" => description_change_validation_request.id,
              "state" => "open",
              "response_due" => "2022-06-27",
              "proposed_description" => "New description",
              "previous_description" => "Current description",
              "rejection_reason" => nil,
              "approved" => nil,
              "days_until_response_due" => 5,
              "cancel_reason" => nil,
              "cancelled_at" => nil
            }
          )
        end
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
