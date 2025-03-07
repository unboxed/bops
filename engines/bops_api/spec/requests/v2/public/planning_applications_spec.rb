# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "BOPS public API" do
  let(:local_authority) { create(:local_authority, :default) }
  let(:application_type) { create(:application_type, :householder) }
  let!(:planning_applications) { create_list(:planning_application, 6, :published, :with_boundary_geojson, :with_press_notice, local_authority:, application_type:, user: create(:user)) }
  let(:page) { 1 }
  let(:maxresults) { 5 }
  let(:invalidated) { create(:planning_application, :with_boundary_geojson_features, :published, local_authority:, application_type:, description: "This is not valid even if marked as published", status: :invalidated) }

  before do
    create_list(:planning_application, 2, :with_boundary_geojson_features, :published, local_authority:, application_type:)
    create_list(:planning_application, 2, :with_boundary_geojson_features, :published, local_authority:, application_type:, description: "I want to build a roof extension.")
  end

  path "/api/v2/public/planning_applications/search" do
    get "Retrieves planning applications based on a search criteria" do
      tags "Planning applications"
      produces "application/json"

      parameter name: :page, in: :query, schema: {
        type: :integer,
        default: 1
      }, required: false

      parameter name: :maxresults, in: :query, schema: {
        type: :integer,
        default: 10
      }, required: false

      parameter name: "q", in: :query, schema: {
        type: :string,
        description: "Search by reference or description"
      }, required: false

      response "200", "returns planning applications when searching by the reference" do
        schema "$ref" => "#/components/schemas/Search"

        let(:page) { 1 }
        let(:q) { planning_applications.first.reference }

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

          expect(data["data"].first["application"]["fullReference"]).to eq("PlanX-#{planning_applications.first.reference}")
        end
      end

      it "validates successfully against the example search json" do
        resolved_schema = load_and_resolve_schema(name: "search", version: BopsApi::Schemas::DEFAULT_ODP_VERSION)
        schemer = JSONSchemer.schema(resolved_schema)
        example_json = example_fixture("search.json")

        expect(schemer.valid?(example_json)).to eq(true)
      end

      response "200", "returns planning applications when searching by the description" do
        schema "$ref" => "#/components/schemas/Search"

        let(:page) { 1 }
        let(:q) { "roof extension" }

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

          data["data"].each do |application|
            expect(application["proposal"]["description"]).to include("roof extension")
          end
        end
      end

      response "200", "does not return 'private' applications" do
        schema "$ref" => "#/components/schemas/Search"

        let(:page) { 1 }
        let(:q) { invalidated.reference }

        run_test! do |response|
          data = JSON.parse(response.body)
          metadata = data["metadata"]

          expect(metadata).to eq(
            {
              "page" => 1,
              "results" => 5,
              "from" => 0,
              "to" => 0,
              "total_pages" => 1,
              "total_results" => 0
            }
          )

          expect(data["data"]).to eq([])
        end
      end

      response "200", "returns empty array when no results from search" do
        schema "$ref" => "#/components/schemas/Search"

        let(:page) { 1 }
        let(:q) { "no results found" }

        run_test! do |response|
          data = JSON.parse(response.body)
          metadata = data["metadata"]

          expect(metadata).to eq(
            {
              "page" => 1,
              "results" => 5,
              "from" => 0,
              "to" => 0,
              "total_pages" => 1,
              "total_results" => 0
            }
          )

          expect(data["data"]).to eq([])
        end
      end

      response "200", "returns planning applications when searching by an out of range page and maxresults" do
        schema "$ref" => "#/components/schemas/Search"

        let(:page) { 0 }
        let(:max_results) { 100000 }

        run_test! do |response|
          data = JSON.parse(response.body)
          metadata = data["metadata"]

          expect(metadata).to eq(
            {
              "page" => 1,
              "results" => 5,
              "from" => 1,
              "to" => 5,
              "total_pages" => 2,
              "total_results" => 10
            }
          )
        end
      end

      response "200", "returns planning applications when searching by a reference or description" do
        schema "$ref" => "#/components/schemas/Search"
        example "application/json", :default, example_fixture("search.json")

        let(:page) { 2 }
        let(:maxresults) { 2 }
        let(:q) { "HAPP" }

        run_test! do |response|
          data = JSON.parse(response.body)
          metadata = data["metadata"]

          expect(metadata).to eq(
            {
              "page" => 2,
              "results" => 2,
              "from" => 3,
              "to" => 4,
              "total_pages" => 5,
              "total_results" => 10
            }
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
        example "application/json", :default, example_fixture("show.json")

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
end
