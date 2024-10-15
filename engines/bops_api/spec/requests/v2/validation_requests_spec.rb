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
      state: :open,
      notified_at: 6.weeks.ago
    )
  end
  let!(:other_change_validation_request) do
    create(
      :other_change_validation_request,
      planning_application:,
      state: :closed,
      notified_at: 3.weeks.ago
    )
  end
  let!(:description_change_validation_request) do
    create(
      :description_change_validation_request,
      planning_application:,
      state: :closed,
      notified_at: 8.weeks.ago
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

  path "/api/v2/validation_requests" do
    it "validates successfully against the example validation requests json" do
      resolved_schema = load_and_resolve_schema(name: "validationRequests", version: "odp/v0.7.0")

      schemer = JSONSchemer.schema(resolved_schema)
      example_json = example_fixture("allValidationRequests.json")
      expect(schemer.valid?(example_json)).to eq(true)
    end

    get "Retrieves a paginated list of notified validation requests for an LPA" do
      tags "Validation requests"
      security [bearerAuth: []]
      produces "application/json"

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

      parameter name: :from_date, in: :query, schema: {
        type: :string,
        description: "Only return validation requests notified to the applicant on or after the date",
        format: "date"
      }, required: false

      parameter name: :to_date, in: :query, schema: {
        type: :string,
        description: "Exclude validation requests notified to the applicant after the date",
        format: "date"
      }, required: false

      parameter name: :page, in: :query, schema: {
        type: :integer,
        default: 1
      }, required: false

      parameter name: :maxresults, in: :query, schema: {
        type: :integer,
        default: 10
      }, required: false

      before do
        create(:pre_commencement_condition_validation_request, :pending, planning_application:)
      end

      response "200", "returns notified validation requests" do
        schema "$ref" => "#/components/schemas/ValidationRequests"
        example "application/json", :default, example_fixture("allValidationRequests.json")

        context "when there are no filters" do
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

            types = data["data"].pluck("type")
            expect(types).to eq([
              "DescriptionChangeValidationRequest",
              "RedLineBoundaryChangeValidationRequest",
              "OtherChangeValidationRequest"
            ])
          end
        end

        context "when filtered by type" do
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

            types = data["data"].pluck("type")
            expect(types).to eq([
              "RedLineBoundaryChangeValidationRequest"
            ])
          end
        end

        context "when filtered by a from date" do
          let(:from_date) { 7.weeks.ago.to_date.iso8601 }

          run_test! do |response|
            data = JSON.parse(response.body)
            metadata = data["metadata"]

            expect(metadata).to eq(
              {
                "page" => 1,
                "results" => 5,
                "from" => 1,
                "to" => 2,
                "total_pages" => 1,
                "total_results" => 2
              }
            )

            types = data["data"].pluck("type")
            expect(types).to eq([
              "RedLineBoundaryChangeValidationRequest",
              "OtherChangeValidationRequest"
            ])
          end
        end

        context "when filtered by a to date" do
          let(:to_date) { 4.weeks.ago.to_date.iso8601 }

          run_test! do |response|
            data = JSON.parse(response.body)
            metadata = data["metadata"]

            expect(metadata).to eq(
              {
                "page" => 1,
                "results" => 5,
                "from" => 1,
                "to" => 2,
                "total_pages" => 1,
                "total_results" => 2
              }
            )

            types = data["data"].pluck("type")
            expect(types).to eq([
              "DescriptionChangeValidationRequest",
              "RedLineBoundaryChangeValidationRequest"
            ])
          end
        end

        context "when filtered by a date range" do
          let(:from_date) { 7.weeks.ago.to_date.iso8601 }
          let(:to_date) { 4.weeks.ago.to_date.iso8601 }

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

            types = data["data"].pluck("type")
            expect(types).to eq([
              "RedLineBoundaryChangeValidationRequest"
            ])
          end
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

        run_test!
      end
    end
  end
end
