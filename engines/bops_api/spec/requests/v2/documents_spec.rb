# frozen_string_literal: true

require_relative "../../swagger_helper"

RSpec.describe "BOPS documents API" do
  let(:config) { Rails.configuration }
  let(:local_authority) { create(:local_authority, :default) }
  let(:application_type) { create(:application_type, :householder) }
  let(:public_document) { create(:document, :with_tags, validated: true, publishable: true) }
  let(:private_document) { create(:document, :with_tags, validated: true, publishable: false) }

  let(:token) { "bops_EjWSP1javBbvZFtRYiWs6y5orH4R748qapSGLNZsJw" }
  let!(:api_user) { create(:api_user, token:, local_authority:) }

  let(:planning_application) { create(:planning_application, :with_boundary_geojson, :with_press_notice, :determined, documents: [public_document, private_document], local_authority:, application_type:) }
  let(:reference) { planning_application.reference }

  around do |example|
    travel_to("2025-10-22T10:30:00Z") { example.run }
  end

  path "/api/v2/planning_applications/{reference}/documents" do
    get "Retrieves documents for a planning application" do
      tags "Planning applications"
      security [bearerAuth: []]
      produces "application/json"

      parameter name: :reference, in: :path, schema: {
        type: :string,
        description: "The planning application reference"
      }

      response "200", "returns a planning application's documents and decision notice given a reference" do
        example "application/json", :default, example_fixture("documents.json")
        schema "$ref" => "#/components/schemas/Documents"

        let(:Authorization) { "Bearer bops_EjWSP1javBbvZFtRYiWs6y5orH4R748qapSGLNZsJw" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["application"]["reference"]).to eq(planning_application.reference)
          expect(data["decisionNotice"]["name"]).to eq("decision-notice-PlanX-25-00100-HAPP.pdf")
          expect(data["decisionNotice"]["url"]).to eq("http://planx.bops.services/api/v1/planning_applications/#{planning_application.reference}/decision_notice.pdf")

          expect(data["files"]).to match_array([
            a_hash_including("url" => "http://planx.bops.services/files/#{public_document.blob_key}"),
            a_hash_including("url" => "http://planx.bops.services/files/#{private_document.blob_key}")
          ])
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

      it "validates successfully against the example documents json" do
        resolved_schema = load_and_resolve_schema(name: "documents", version: BopsApi::Schemas::DEFAULT_ODP_VERSION)
        schemer = JSONSchemer.schema(resolved_schema)
        example_json = example_fixture("documents.json")

        expect(schemer.valid?(example_json)).to eq(true)
      end
    end
  end
end
