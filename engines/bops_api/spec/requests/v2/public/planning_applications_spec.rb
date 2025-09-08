# frozen_string_literal: true

require_relative "../../../swagger_helper"

RSpec.describe "BOPS public API" do
  let(:local_authority) { create(:local_authority, :default) }
  let(:application_type) { create(:application_type, :householder) }
  let!(:planning_applications) do
    create_list(
      :planning_application, 6,
      :published,
      :with_boundary_geojson,
      :with_press_notice,
      local_authority: local_authority,
      application_type: application_type,
      user: create(:user)
    )
  end

  let(:submission) { create(:planx_planning_data, params_v2: example_fixture("application/planningPermission/fullHouseholder.json")) }
  let(:planning_application_with_submission) { create(:planning_application, :planning_permission, :published, local_authority:, planx_planning_data: submission) }

  let(:page) { 1 }
  let(:resultsPerPage) { 5 }
  let(:invalidated) { create(:planning_application, :with_boundary_geojson_features, :published, local_authority:, application_type:, description: "This is not valid even if marked as published", status: :invalidated) }
  let("applicationStatus[]") { [] }
  let("applicationType[]") { [] }
  let("councilDecision") { nil }
  let(:orderBy) { "desc" }
  let(:sortBy) { "publishedAt" }

  let(:invalidated) do
    create(
      :planning_application,
      :with_boundary_geojson_features,
      :published,
      local_authority: local_authority,
      application_type: application_type,
      description: "This is not valid even if marked as published",
      status: :invalidated
    )
  end

  before do
    create_list(
      :planning_application, 2,
      :with_boundary_geojson_features,
      :published,
      local_authority: local_authority,
      application_type: application_type
    )
    create_list(
      :planning_application, 2,
      :with_boundary_geojson_features,
      :published,
      local_authority: local_authority,
      application_type: application_type,
      description: "I want to build a roof extension."
    )
  end

  path "/api/v2/public/planning_applications/search" do
    get "Retrieves planning applications based on a search criteria" do
      tags "Planning applications"
      produces "application/json"

      with_search_and_filter_params

      parameter name: :resultsPerPage, in: :query, schema: {
        type: :integer,
        default: 5,
        minimum: 1,
        maximum: BopsApi::Postsubmission::PostsubmissionPagination::MAXRESULTS_LIMIT
      }, required: false

      parameter name: :query, in: :query, schema: {
        type: :string,
        description: "Search by reference or description"
      }, required: false

      parameter name: "applicationType[]", in: :query, style: :form, explode: true, schema: {
        type: :array,
        items: {
          type: :string
        },
        description: "Filter by one or more application type codes"
      }

      parameter name: :orderBy, in: :query, schema: {
        type: :string,
        description: "Sort by ascending or descending order",
        enum: ["asc", "desc"],
        default: "desc"
      }

      parameter name: :sortBy, in: :query, schema: {
        type: :string,
        description: "Sort by field",
        enum: ["publishedAt", "receivedAt"],
        default: "receivedAt"
      }

      response "200", "returns planning applications when searching by the reference" do
        schema "$ref" => "#/components/schemas/PublicSearch"

        let(:query) { planning_applications.first.reference }

        run_test! do |response|
          data = JSON.parse(response.body)
          pagination = data["pagination"]

          expect(pagination).to eq(
            "resultsPerPage" => 5,
            "currentPage" => 1,
            "totalPages" => 1,
            "totalResults" => 1,
            "totalAvailableItems" => 10
          )

          expect(
            data["data"].first["application"]["fullReference"]
          ).to eq("PlanX-#{planning_applications.first.reference}")
        end
      end

      it "validates successfully against the example search json" do
        resolved_schema = load_and_resolve_schema(
          name: "search",
          version: BopsApi::Schemas::DEFAULT_ODP_VERSION
        )
        schemer = JSONSchemer.schema(resolved_schema)
        example_json = example_fixture("public/search.json")

        expect(schemer.valid?(example_json)).to eq(true)
      end

      response "200", "returns planning applications when searching by the description" do
        schema "$ref" => "#/components/schemas/PublicSearch"

        let(:query) { "roof extension" }

        run_test! do |response|
          data = JSON.parse(response.body)
          pagination = data["pagination"]

          expect(pagination).to eq(
            "resultsPerPage" => 5,
            "currentPage" => 1,
            "totalPages" => 1,
            "totalResults" => 2,
            "totalAvailableItems" => 10
          )

          data["data"].each do |application|
            expect(
              application["proposal"]["description"]
            ).to include("roof extension")
          end
        end
      end

      response "200", "does not return 'private' applications" do
        schema "$ref" => "#/components/schemas/PublicSearch"

        let(:query) { invalidated.reference }

        run_test! do |response|
          data = JSON.parse(response.body)
          pagination = data["pagination"]

          expect(pagination).to eq(
            "resultsPerPage" => 5,
            "currentPage" => 1,
            "totalPages" => 1,
            "totalResults" => 0,
            "totalAvailableItems" => 10
          )

          expect(data["data"]).to eq([])
        end
      end

      response "200", "returns empty array when no results from search" do
        schema "$ref" => "#/components/schemas/PublicSearch"

        let(:query) { "no results found" }

        run_test! do |response|
          data = JSON.parse(response.body)
          pagination = data["pagination"]

          expect(pagination).to eq(
            "resultsPerPage" => 5,
            "currentPage" => 1,
            "totalPages" => 1,
            "totalResults" => 0,
            "totalAvailableItems" => 10
          )

          expect(data["data"]).to eq([])
        end
      end

      response "200", "returns planning applications when searching by an out of range page and resultsPerPage" do
        schema "$ref" => "#/components/schemas/PublicSearch"

        let(:page) { 0 }
        let(:resultsPerPage) { 100_000 }

        run_test! do |response|
          data = JSON.parse(response.body)
          pagination = data["pagination"]

          expect(pagination).to eq(
            "resultsPerPage" => BopsApi::Postsubmission::PostsubmissionPagination::MAXRESULTS_LIMIT,
            "currentPage" => 1,
            "totalPages" => 1,
            "totalResults" => 10,
            "totalAvailableItems" => 10
          )
        end
      end

      response "200", "returns planning applications when searching by a reference or description" do
        schema "$ref" => "#/components/schemas/PublicSearch"
        example "application/json", :default, example_fixture("public/search.json")

        let(:page) { 2 }
        let(:resultsPerPage) { 2 }
        let(:query) { "HAPP" }

        run_test! do |response|
          data = JSON.parse(response.body)
          pagination = data["pagination"]

          expect(pagination).to eq(
            "resultsPerPage" => 2,
            "currentPage" => page,
            "totalPages" => 5,
            "totalResults" => 10,
            "totalAvailableItems" => 10
          )
        end
      end
    end
  end

  path "/api/v2/public/planning_applications/{reference}" do
    get "Retrieves a planning application" do
      tags "Planning applications"
      produces "application/json"

      parameter name: :reference, in: :path, schema: {
        type: :string,
        description: "The planning application reference"
      }

      response "200", "returns a planning application given a reference" do
        example "application/json", :default, example_fixture("public/show.json")

        let!(:planning_application) { planning_applications.first }
        let!(:appeal) { create(:appeal, planning_application:) }
        let(:reference) { planning_application.reference }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["application"]["reference"]).to eq(planning_application.reference)
          expect(data["application"]["status"]).to eq("Appeal lodged")
          expect(data["data"]["appeal"]["reason"]).not_to be_empty
          expect(data["data"]["appeal"]["lodgedDate"]).to match(/\d{4}-\d{2}-\d{2}/)

          expect(data["officer"]["name"]).to eq(planning_application.user.name)

          press_notice = planning_application.press_notice
          press_notice_response = data["application"]["pressNotice"]
          expect(press_notice_response["required"]).to eq(press_notice.required)
          expect(press_notice_response["reason"]).to eq(press_notice.reason)
        end
      end
    end
  end

  path "/api/v2/public/planning_applications/{reference}/submission" do
    it "validates successfully against the example applicationSubmission json" do
      resolved_schema = load_and_resolve_schema(name: "applicationSubmission", version: BopsApi::Schemas::DEFAULT_ODP_VERSION)

      schemer = JSONSchemer.schema(resolved_schema)
      example_json = example_fixture("applicationSubmission.json")
      expect(schemer.valid?(example_json)).to eq(true)
    end

    get "Retrieves the planning application submission given a reference" do
      tags "Planning applications"
      produces "application/json"

      parameter name: :reference, in: :path, schema: {
        type: :string,
        description: "The planning application reference"
      }

      response "200", "returns planning application submission when searching by the reference" do
        example "application/json", :default, example_fixture("whitelistApplicationSubmission.json")
        schema "$ref" => "#/components/schemas/ApplicationSubmission"

        let(:reference) { planning_application_with_submission.reference }
        let(:redacted_submission) { BopsApi::Application::PublicSubmissionWhitelistingService.new(planning_application: planning_application_with_submission).call }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["application"]["reference"]).to eq(reference)
          expect(redacted_submission.dig("data", "application")).not_to have_key("extra_field")
          expect(redacted_submission.dig("data")).not_to have_key("fee")
          expect(redacted_submission.dig("data", "applicant")).not_to have_key("email")
        end
      end
    end
  end
end
