# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "BOPS public API" do
  let(:local_authority) { create(:local_authority, :default) }
  let(:application_type) { create(:application_type, :householder) }
  let!(:planning_applications) { create_list(:planning_application, 6, :with_boundary_geojson, local_authority:, application_type:, make_public: true) }
  let(:maxresults) { 5 }
  let(:q) { "" }

  before do
    create_list(:planning_application, 2, :with_boundary_geojson_features, local_authority:, application_type:, make_public: true)
    create_list(:planning_application, 2, :with_boundary_geojson_features, local_authority:, application_type:, make_public: true, description: "I want to build a roof extension.")
  end

  path "/api/v2/public/planning_applications/search" do
    get "Retrieves planning applications based on a search criteria" do
      tags "Planning applications"
      produces "application/json"

      parameter name: :page, in: :query, schema: {
        type: :integer,
        default: 1
      }

      parameter name: :maxresults, in: :query, schema: {
        type: :integer,
        default: 10
      }

      parameter name: "q", in: :query, schema: {
        type: :string,
        description: "Search by reference or description"
      }

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

          expect(data["data"].first["application"]["full_reference"]).to eq("PlanX-#{planning_applications.first.reference}")
        end
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
end
