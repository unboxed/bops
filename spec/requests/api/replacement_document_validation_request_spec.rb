# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Replacement document validation requests API", show_exceptions: true do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:api_user) { create(:api_user, local_authority: default_local_authority) }
  let!(:planning_application) { create(:planning_application, :invalidated, local_authority: default_local_authority) }
  let(:document) { create(:document) }

  let!(:replacement_document_validation_request) do
    create(
      :replacement_document_validation_request,
      planning_application:,
      created_at: DateTime.new(2022, 1, 1),
      old_document: document
    )
  end

  let(:token) { "Bearer #{api_user.token}" }

  let(:processed_active_storage_variant) do
    instance_double(
      ActiveStorage::VariantWithRecord,
      url: "http://www.example.com/test_image"
    )
  end

  describe "#index" do
    let(:path) do
      api_v1_planning_application_replacement_document_validation_requests_path(
        planning_application
      )
    end

    let!(:replacement_document_validation_request2) do
      create(
        :replacement_document_validation_request,
        :with_response,
        :closed,
        planning_application:,
        created_at: DateTime.new(2022, 1, 2)
      )
    end

    let!(:replacement_document_validation_request3) do
      create(
        :replacement_document_validation_request,
        :cancelled,
        planning_application:,
        created_at: DateTime.new(2022, 1, 3),
        cancelled_at: DateTime.new(2022, 1, 4)
      )
    end

    context "when the request is valid" do
      before do
        allow_any_instance_of(ActiveStorage::VariantWithRecord)
          .to receive(:processed)
          .and_return(processed_active_storage_variant)
      end

      it "is successful" do
        get(
          path,
          params: {change_access_id: planning_application.change_access_id},
          headers: {"CONTENT-TYPE": "application/json", Authorization: token}
        )

        expect(response).to be_successful
      end

      it "returns the request data" do
        travel_to(DateTime.new(2022, 1, 2)) do
          get(
            path,
            params: {change_access_id: planning_application.change_access_id},
            headers: {"CONTENT-TYPE": "application/json", Authorization: token}
          )
        end

        expect(json["data"]).to contain_exactly(
          {
            id: replacement_document_validation_request.id,
            state: "open",
            response_due: "2022-01-25",
            days_until_response_due: 15,
            cancel_reason: nil,
            cancelled_at: nil,
            old_document: {
              name: "proposed-floorplan.png",
              invalid_document_reason: "Document is invalid",
              url: "http://www.example.com/test_image"
            }
          }.deep_stringify_keys,
          {
            id: replacement_document_validation_request2.id,
            state: "closed",
            response_due: "2022-01-25",
            days_until_response_due: 15,
            cancel_reason: nil,
            cancelled_at: nil,
            old_document: {
              name: "proposed-floorplan.png",
              invalid_document_reason: "Document is invalid",
              url: "http://www.example.com/test_image"
            },
            new_document: {
              name: "proposed-floorplan.png",
              url: "http://www.example.com/test_image"
            }
          }.deep_stringify_keys,
          {
            id: replacement_document_validation_request3.id,
            state: "cancelled",
            response_due: "2022-01-25",
            days_until_response_due: 15,
            cancel_reason: "Made by mistake!",
            cancelled_at: "2022-01-04T00:00:00.000+00:00",
            old_document: {
              name: "proposed-floorplan.png",
              invalid_document_reason: nil,
              url: "http://www.example.com/test_image"
            }
          }.deep_stringify_keys
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
      api_v1_planning_application_replacement_document_validation_request_path(
        planning_application,
        replacement_document_validation_request
      )
    end

    context "when the request is valid" do
      before do
        allow_any_instance_of(ActiveStorage::VariantWithRecord)
          .to receive(:processed)
          .and_return(processed_active_storage_variant)
      end

      it "is successful" do
        get(
          path,
          params: {change_access_id: planning_application.change_access_id},
          headers: {"CONTENT-TYPE": "application/json", Authorization: token}
        )

        expect(response).to be_successful
      end

      it "returns the request data" do
        travel_to(DateTime.new(2022, 1, 2)) do
          get(
            path,
            params: {change_access_id: planning_application.change_access_id},
            headers: {"CONTENT-TYPE": "application/json", Authorization: token}
          )
        end

        expect(json).to eq(
          {
            id: replacement_document_validation_request.id,
            state: "open",
            response_due: "2022-01-25",
            days_until_response_due: 15,
            cancel_reason: nil,
            cancelled_at: nil,
            old_document: {
              name: "proposed-floorplan.png",
              invalid_document_reason: "Document is invalid",
              url: "http://www.example.com/test_image"
            }
          }.deep_stringify_keys
        )
      end

      context "when the image is missing" do
        before do
          allow_any_instance_of(ActiveStorage::VariantWithRecord)
            .to receive(:processed)
            .and_raise(ActiveStorage::PreviewError.new("Document stream is empty"))
        end

        it "is successful" do
          get(
            path,
            params: {change_access_id: planning_application.change_access_id},
            headers: {"CONTENT-TYPE": "application/json", Authorization: token}
          )

          expect(response).to be_successful
        end

        it "returns the request data without a document url" do
          travel_to(DateTime.new(2022, 1, 2)) do
            get(
              path,
              params: {change_access_id: planning_application.change_access_id},
              headers: {"CONTENT-TYPE": "application/json", Authorization: token}
            )
          end

          expect(json).to eq(
            {
              id: replacement_document_validation_request.id,
              state: "open",
              response_due: "2022-01-25",
              days_until_response_due: 15,
              cancel_reason: nil,
              cancelled_at: nil,
              old_document: {
                name: "proposed-floorplan.png",
                invalid_document_reason: "Document is invalid",
                url: nil
              }
            }.deep_stringify_keys
          )
        end

        it "logs the error" do
          expect(Rails.logger)
            .to receive(:warn)
            .with("Image retrieval failed for document ##{document.id} with error 'Document stream is empty'")

          get(
            path,
            params: {change_access_id: planning_application.change_access_id},
            headers: {"CONTENT-TYPE": "application/json", Authorization: token}
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
