# frozen_string_literal: true

require_relative "../../swagger_helper"

RSpec.describe "BOPS API" do
  let(:local_authority) { create(:local_authority, :default) }
  let(:application_type) { create(:application_type, :householder) }
  let(:document) { create(:document, :with_tags, validated: true, publishable: true) }

  let(:token) { "bops_EjWSP1javBbvZFtRYiWs6y5orH4R748qapSGLNZsJw" }
  let!(:api_user) { create(:api_user, permissions: %w[comment:read], token:, local_authority:) }
  let!(:Authorization) { "Bearer #{token}" }

  around do |example|
    travel_to("2024-10-22T10:30:00Z") { example.run }
  end

  path "/api/v2/neighbour_responses" do
    get "Retrieves neighbour responses for a planning application" do
      tags "Planning applications"
      security [bearerAuth: []]
      produces "application/json"

      response "200", "returns a list of neighbour responses" do
        example "application/json", :default, example_fixture("neighbourResponses.json")
        schema "$ref" => "#/components/schemas/NeighbourResponses"

        let(:reference) { planning_application.reference }
        let(:planning_application) { create(:planning_application, :published, local_authority:, application_type:) }

        before do
          create(:neighbour_response, neighbour: create(:neighbour, consultation: planning_application.consultation))
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["responses"]).not_to be_empty
        end
      end

      it "validates successfully against the example neighbour responses json" do
        resolved_schema = load_and_resolve_schema(name: "neighbourResponses", version: BopsApi::Schemas::DEFAULT_ODP_VERSION)
        schemer = JSONSchemer.schema(resolved_schema)
        example_json = example_fixture("neighbourResponses.json")

        expect(schemer.valid?(example_json)).to eq(true)
      end
    end
  end
end
