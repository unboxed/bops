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

  let(:page) { 1 }
  let(:resultsPerPage) { 5 }

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

      parameter name: :page, in: :query, schema: {
        type: :integer,
        default: 1
      }, required: false

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
        let!(:appeal) { create(:appeal, planning_application: planning_application) }
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
end
