# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "BOPS public API" do
  let(:local_authority) { create(:local_authority, :default) }
  let(:application_type) { create(:application_type, :householder) }
  let(:document) { create(:document, :with_tags, validated: true, publishable: true) }
  let(:planning_application) { create(:planning_application, :published, :with_boundary_geojson, :determined, documents: [document], local_authority:, application_type:) }

  path "/api/v2/public/planning_applications/{reference}/documents" do
    get "Retrieves documents for a planning application" do
      tags "Planning applications"
      produces "application/json"

      parameter name: :reference, in: :path, schema: {
        type: :string,
        description: "The planning application reference"
      }

      response "200", "returns a planning application's documents and decision notice given a reference" do
        example "application/json", :default, example_fixture("documents.json")
        schema "$ref" => "#/components/schemas/Documents"

        let(:reference) { planning_application.reference }
        let(:planning_application) { create(:planning_application, :published, :with_boundary_geojson, :determined, documents: [document], local_authority:, application_type:) }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["application"]["reference"]).to eq(planning_application.reference)
          expect(data["files"]).not_to be_empty
          expect(data["decisionNotice"]["name"]).to eq("decision-notice-PlanX-24-00100-HAPP.pdf")
          expect(data["decisionNotice"]["url"]).to eq("http://planx.example.com/api/v1/planning_applications/#{planning_application.id}/decision_notice.pdf")
        end
      end

      it "validates successfully against the example documents json" do
        resolved_schema = load_and_resolve_schema(name: "documents", version: "odp/v0.6.0")
        schemer = JSONSchemer.schema(resolved_schema)
        example_json = example_fixture("documents.json")

        expect(schemer.valid?(example_json)).to eq(true)
      end
    end
  end

  context "when there is a site_notice" do
    let!(:site_notice) do
      create(:site_notice,
        planning_application: planning_application,
        required: true,
        displayed_at: "2024-01-08T09:00:00Z",
        expiry_date: "2024-01-30",
        internal_team_email: "pressteam@example.com")
    end

    let!(:site_notice_evidence) do
      create(:document,
        :public,
        planning_application: planning_application,
        owner: site_notice,
        file: fixture_file_upload("site-notice.jpg", "image/jpeg", true),
        tags: ["internal.siteNotice"])
    end

    path "/api/v2/public/planning_applications/{reference}/documents" do
      get "Retrieves documents for a planning application" do
        tags "Planning applications"
        produces "application/json"

        parameter name: :reference, in: :path, schema: {
          type: :string,
          description: "The planning application reference"
        }

        response "200", "returns a planning application's documents and decision notice given a reference" do
          example "application/json", :default, example_fixture("documents.json")
          schema "$ref" => "#/components/schemas/Documents"

          let(:reference) { planning_application.reference }
          let(:planning_application) { create(:planning_application, :published, :with_boundary_geojson, :determined, documents: [document], local_authority:, application_type:) }

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data["application"]["reference"]).to eq(planning_application.reference)
            expect(data["files"].count).to be(2)
            expect(data["files"].last["name"]).to eq("site-notice.jpg")
            expect(data["files"].last["type"].first["description"]).to eq("Site Notice")
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
end
