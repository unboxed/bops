# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "BOPS public API" do
  let(:local_authority) { create(:local_authority, :default) }
  let(:application_type) { create(:application_type, :householder) }
  let!(:planning_applications) { create_list(:planning_application, 8, :with_boundary_geojson, local_authority:, application_type:, make_public: true) }
  let(:maxresults) { 5 }

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
        example "application/json", :default, api_json_fixture("public/planning_applications/search.json")

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

      response "200", "returns empty array when no results from search" do
        example "application/json", :default, api_json_fixture("public/planning_applications/search.json")

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

      response "200", "returns planning applications when searching by a reference or description" do
        example "application/json", :default, api_json_fixture("public/planning_applications/search.json")

        let(:page) { 1 }
        let(:q) { "HAPP" }

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
              "total_results" => 8
            }
          )
        end
      end
    end
  end
end
