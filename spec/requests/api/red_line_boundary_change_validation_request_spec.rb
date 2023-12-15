# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Red line boundary change validation requests API", show_exceptions: true do
  let!(:api_user) { create(:api_user) }
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:planning_application) { create(:planning_application, :invalidated, :with_boundary_geojson, local_authority: default_local_authority) }
  let!(:red_line_boundary_change_validation_request) do
    travel_to(DateTime.new(2023, 12, 15)) { create(:red_line_boundary_change_validation_request, planning_application:) }
  end
  let(:token) { "Bearer #{api_user.token}" }

  describe "#index" do
    let(:path) { "/api/v1/planning_applications/#{planning_application.id}/red_line_boundary_change_validation_requests" }
    let!(:red_line_boundary_change_validation_request2) do
      travel_to(DateTime.new(2023, 12, 15)) { create(:red_line_boundary_change_validation_request, :closed, planning_application:) }
    end

    context "when the request is successful" do
      before do
        travel_to(DateTime.new(2023, 12, 15))
      end

      it "retrieves all red line boundary change validation requests for a given planning application" do
        get "#{path}?change_access_id=#{planning_application.change_access_id}",
          headers: {"CONTENT-TYPE": "application/json", Authorization: token}

        expect(response).to be_successful
        expect(sort_by_id(json["data"])).to eq(
          [
            {
              "id" => red_line_boundary_change_validation_request.id,
              "state" => "open",
              "response_due" => red_line_boundary_change_validation_request.response_due.to_fs(:db),
              "new_geojson" => red_line_boundary_change_validation_request.new_geojson,
              "reason" => "Boundary incorrect",
              "original_geojson" => red_line_boundary_change_validation_request.planning_application.boundary_geojson,
              "rejection_reason" => nil,
              "approved" => nil,
              "days_until_response_due" => 15,
              "cancel_reason" => nil,
              "cancelled_at" => nil
            },
            {
              "id" => red_line_boundary_change_validation_request2.id,
              "state" => "closed",
              "response_due" => red_line_boundary_change_validation_request2.response_due.to_fs(:db),
              "new_geojson" => red_line_boundary_change_validation_request2.new_geojson,
              "reason" => "Boundary incorrect",
              "original_geojson" => red_line_boundary_change_validation_request.planning_application.boundary_geojson,
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
        let(:path) { "/api/v1/planning_applications/#{planning_application.id + 1}/red_line_boundary_change_validation_requests" }

        it_behaves_like "ApiRequest::NotFound", "planning_application"
      end
    end
  end

  describe "#show" do
    let(:path) do
      "/api/v1/planning_applications/#{planning_application.id}/red_line_boundary_change_validation_requests/#{red_line_boundary_change_validation_request.id}"
    end

    context "when the request is successful" do
      before do
        travel_to(DateTime.new(2023, 12, 15))
      end

      it "retrieves a red line boundary change validation request for a given planning application" do
        get "#{path}?change_access_id=#{planning_application.change_access_id}",
          headers: {"CONTENT-TYPE": "application/json", Authorization: token}

        expect(response).to be_successful
        expect(json).to eq(
          {
            "id" => red_line_boundary_change_validation_request.id,
            "state" => "open",
            "response_due" => red_line_boundary_change_validation_request.response_due.to_fs(:db),
            "new_geojson" => red_line_boundary_change_validation_request.new_geojson,
            "reason" => "Boundary incorrect",
            "original_geojson" => red_line_boundary_change_validation_request.planning_application.boundary_geojson,
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
          "/api/v1/planning_applications/#{planning_application.id + 1}/red_line_boundary_change_validation_requests/#{red_line_boundary_change_validation_request.id}"
        end

        it_behaves_like "ApiRequest::NotFound", "planning_application"
      end

      describe "when the red line boundary change validation request is not found" do
        let(:path) do
          "/api/v1/planning_applications/#{planning_application.id}/red_line_boundary_change_validation_requests/#{red_line_boundary_change_validation_request.id + 1}"
        end

        it_behaves_like "ApiRequest::NotFound", "red_line_boundary_change_validation_request"
      end
    end
  end
end
