# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "BOPS API" do
  let(:local_authority) { create(:local_authority, :default) }
  let(:southwark) { create(:local_authority, :southwark) }
  let(:application_type) { create(:application_type) }
  let!(:planning_application) { create(:planning_application, :invalidated, :with_boundary_geojson, local_authority:, application_type:) }

  let!(:red_line_boundary_change_validation_request) do
    create(
      :red_line_boundary_change_validation_request,
      planning_application:,
      state: :open
    )
  end
  let!(:other_change_validation_request) do
    create(
      :other_change_validation_request,
      planning_application:,
      state: :closed
    )
  end
  let!(:description_change_validation_request) do
    create(
      :description_change_validation_request,
      planning_application:,
      state: :closed
    )
  end

  before do
    create(:api_user, token: "bRPkCPjaZExpUYptBJDVFzss", local_authority:)
    create(:api_user, name: "other", token: "pUYptBJDVFzssbRPkCPjaZEx", local_authority: southwark)
    create(:application_type, :ldc_existing)

    Rails.configuration.os_vector_tiles_api_key = "testtest"
  end

  let(:Authorization) { "Bearer bRPkCPjaZExpUYptBJDVFzss" }
  let(:page) { 1 }
  let(:maxresults) { 5 }

  path "/api/v2/planning_applications/{reference}/validation_requests" do
    it "validates successfully against the example validation requests json" do
      resolved_schema = load_and_resolve_schema(name: "validationRequests", version: "odp/v0.7.0")

      schemer = JSONSchemer.schema(resolved_schema)
      example_json = example_fixture("validationRequests.json")
      expect(schemer.valid?(example_json)).to eq(true)
    end

    get "Retrieves the validation requests for an application" do
      tags "Validation requests"
      security [bearerAuth: []]
      produces "application/json"

      parameter name: :reference, in: :path, schema: {
        type: :string,
        description: "The planning application reference"
      }

      parameter name: :type, in: :query, schema: {
        type: :string,
        enum: [
          "AdditionalDocumentValidationRequest",
          "DescriptionChangeValidationRequest",
          "RedLineBoundaryChangeValidationRequest",
          "ReplacementDocumentValidationRequest",
          "OwnershipCertificateValidationRequest",
          "OtherChangeValidationRequest",
          "FeeChangeValidationRequest",
          "PreCommencementConditionValidationRequest",
          "HeadsOfTermsValidationRequest",
          "TimeExtensionValidationRequest"
        ]
      }, required: false

      parameter name: :page, in: :query, schema: {
        type: :integer,
        default: 1
      }, required: false

      parameter name: :maxresults, in: :query, schema: {
        type: :integer,
        default: 10
      }, required: false

      response "200", "returns application validation requests when searching by the reference and type" do
        schema "$ref" => "#/components/schemas/ValidationRequests"

        let(:reference) { planning_application.reference }
        let(:type) { "RedLineBoundaryChangeValidationRequest" }

        run_test! do |response|
          data = JSON.parse(response.body)
          metadata = data["metadata"]

          expect(metadata).to eq(
            {
              "page" => 1,
              "results" => 5,
              "from" => 1,
              "to" => 1,
              "total_pages" => 1,
              "total_results" => 1
            }
          )

          type = data["data"].pluck("type").uniq
          expect(type).to eq(["RedLineBoundaryChangeValidationRequest"])
        end
      end

      response "200", "returns application validation requests when searching by the reference" do
        example "application/json", :default, example_fixture("validationRequests.json")
        schema "$ref" => "#/components/schemas/ValidationRequests"

        let(:reference) { planning_application.reference }

        run_test! do |response|
          data = JSON.parse(response.body)
          metadata = data["metadata"]

          expect(metadata).to eq(
            {
              "page" => 1,
              "results" => 5,
              "from" => 1,
              "to" => 3,
              "total_pages" => 1,
              "total_results" => 3
            }
          )

          type = data["data"].pluck("type")
          expect(type).to eq(["RedLineBoundaryChangeValidationRequest", "OtherChangeValidationRequest", "DescriptionChangeValidationRequest"])
        end
      end

      response "401", "with missing or invalid credentials" do
        schema "$ref" => "#/components/schemas/UnauthorizedError"

        example "application/json", :default, {
          error: {
            code: 401,
            message: "Unauthorized"
          }
        }

        let(:Authorization) { "Bearer invalid-credentials" }
        let(:reference) { planning_application.reference }

        run_test!
      end
    end
  end
end
