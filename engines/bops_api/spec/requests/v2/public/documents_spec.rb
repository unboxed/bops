# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "BOPS public API" do
  let(:local_authority) { create(:local_authority, :default) }
  let(:application_type) { create(:application_type, :householder) }
  let(:document) { create(:document, validated: true, publishable: true) }
  let(:planning_application) { create(:planning_application, :published, :with_boundary_geojson, documents: [document], local_authority:, application_type:) }

  path "/api/v2/public/planning_applications/{id}/documents" do
    get "Retrieves documents for a planning application" do
      tags "Planning applications"
      produces "application/json"

      parameter name: :id, in: :path, schema: {
        oneOf: [
          {type: :string, pattern: "\d{2}-\d{5}-[A-Za-z0-9]+"},
          {type: :integer}
        ],
        description: "The planning application reference or ID"
      }

      response "200", "returns a planning application's documents given an ID" do
        example "application/json", :default, api_json_fixture("planning_applications/documents.json")
        schema "$ref" => "#/components/schemas/Documents"

        let(:id) { planning_application.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["application"]["reference"]).to eq(planning_application.reference)
          expect(data["files"]).not_to be_empty
        end
      end

      response "200", "returns a planning application's documents given a reference" do
        example "application/json", :default, api_json_fixture("planning_applications/documents.json")
        schema "$ref" => "#/components/schemas/Documents"

        let(:id) { planning_application.reference }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["application"]["reference"]).to eq(planning_application.reference)
          expect(data["files"]).not_to be_empty
        end
      end

      it "validates successfully against the example documents json" do
        schema = BopsApi::Schemas.find!("documents", version: "odp/v0.6.0").value
        schemer = JSONSchemer.schema(schema)

        expect(schemer.valid?(example_fixture("documents.json"))).to eq(true)
      end
    end
  end
end
