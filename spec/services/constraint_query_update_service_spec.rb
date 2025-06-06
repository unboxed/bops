# frozen_string_literal: true

require "rails_helper"

RSpec.describe ConstraintQueryUpdateService, type: :service do
  let(:response_with_one_constraint) do
    {
      sourceRequest: "https://www.planning.data.gov.uk/entity.json?entries=current&geometry=POLYGON+%28%28-0.07629275321961124+51.48596289289142%2C+-0.0763061642646857+51.48591028066045%2C+-0.07555112242699404+51.48584764697301%2C+-0.07554173469544191+51.48590192950712%2C+-0.07629275321961124+51.48596289289142%29%29&geometry_relation=intersects&limit=100&dataset=article-4-direction-area&dataset=central-activities-zone&dataset=listed-building&dataset=listed-building-outline&dataset=locally-listed-building&dataset=park-and-garden&dataset=conservation-area&dataset=area-of-outstanding-natural-beauty&dataset=national-park&dataset=world-heritage-site&dataset=world-heritage-site-buffer-zone&dataset=special-protection-area&dataset=scheduled-monument&dataset=tree&dataset=tree-preservation-order&dataset=tree-preservation-zone&dataset=site-of-special-scientific-interest&dataset=special-area-of-conservation&dataset=ancient-woodland",
      constraints: {
        tpo: {
          fn: "tpo",
          value: true,
          text: "is in a Tree Preservation Order (TPO) Zone",
          data: [
            {
              "entry-date": "2021-12-02",
              "start-date": "1993-01-13",
              "end-date": "",
              entity: 19_109_825,
              name: "School Nature Area, Cobourg Road",
              dataset: "tree-preservation-zone",
              typology: "geography",
              reference: "",
              prefix: "tree-preservation-zone",
              "organisation-entity": "329",
              "tree-preservation-type": "Woodland",
              "tree-preservation-order": "228"
            }
          ],
          category: "Trees"
        },
        article4: {
          fn: "article4",
          value: false,
          text: "is not subject to local permitted development restrictions (known as Article 4 directions)",
          category: "General policy"
        }
      }
    }.to_json
  end

  let(:response_with_no_constraints) do
    {
      sourceRequest: "https://www.planning.data.gov.uk/entity.json?entries=current&geometry=POLYGON+%28%28-0.07629275321961124+51.48596289289142%2C+-0.0763061642646857+51.48591028066045%2C+-0.07555112242699404+51.48584764697301%2C+-0.07554173469544191+51.48590192950712%2C+-0.07629275321961124+51.48596289289142%29%29&geometry_relation=intersects&limit=100&dataset=article-4-direction-area&dataset=central-activities-zone&dataset=listed-building&dataset=listed-building-outline&dataset=locally-listed-building&dataset=park-and-garden&dataset=conservation-area&dataset=area-of-outstanding-natural-beauty&dataset=national-park&dataset=world-heritage-site&dataset=world-heritage-site-buffer-zone&dataset=special-protection-area&dataset=scheduled-monument&dataset=tree&dataset=tree-preservation-order&dataset=tree-preservation-zone&dataset=site-of-special-scientific-interest&dataset=special-area-of-conservation&dataset=ancient-woodland",
      constraints: {
        tpo: {
          fn: "tpo",
          value: false,
          text: "is in a Tree Preservation Order (TPO) Zone",
          category: "Trees"
        },
        article4: {
          fn: "article4",
          value: false,
          text: "is not subject to local permitted development restrictions (known as Article 4 directions)",
          category: "General policy"
        }
      }
    }.to_json
  end

  describe "#call" do
    let!(:api_user) { create(:api_user, :planx) }
    let!(:local_authority1) { create(:local_authority) }
    let!(:local_authority2) { create(:local_authority, :southwark) }

    let!(:planning_application) { create(:planning_application, local_authority: local_authority1, api_user:) }

    context "when the query responds with some constraints" do
      let!(:constraint) { create(:constraint, :tpo) }

      before do
        stub_planx_api_response_for("POLYGON ((-0.07629275321961124 51.48596289289142, -0.0763061642646857 51.48591028066045, -0.07555112242699404 51.48584764697301, -0.07554173469544191 51.48590192950712, -0.07629275321961124 51.48596289289142))").to_return(
          status: 200, body: response_with_one_constraint
        )
      end

      it "creates some constraints" do
        planning_application.boundary_geojson = {"type" => "Polygon", "coordinates" => [[[-0.07629275321961124, 51.48596289289142], [-0.07630616426468570, 51.48591028066045], [-0.07555112242699404, 51.48584764697301], [-0.07554173469544191, 51.48590192950712], [-0.07629275321961124, 51.48596289289142]]]}
        planning_application.save!
        perform_enqueued_jobs

        expect(planning_application.planning_application_constraints).not_to be_empty
      end
    end

    context "when the query responds with no constraints" do
      before do
        stub_planx_api_response_for("POLYGON ((-0.07629275321961124 51.48596289289142, -0.0763061642646857 51.48591028066045, -0.07555112242699404 51.48584764697301, -0.07554173469544191 51.48590192950712, -0.07629275321961124 51.48596289289142))").to_return(
          status: 200, body: response_with_no_constraints
        )
      end

      it "does not create any constraints" do
        planning_application.boundary_geojson = '{"type":"Polygon","coordinates":[[[-0.07629275321961124,51.48596289289142],[-0.07630616426468570,51.48591028066045],[-0.07555112242699404,51.48584764697301],[-0.07554173469544191,51.48590192950712],[-0.07629275321961124,51.48596289289142]]]}'
        planning_application.save!
        perform_enqueued_jobs
        expect(planning_application.planning_application_constraints).to be_empty
      end
    end

    context "when the application has no geodata" do
      it "does not throw an exception" do
        planning_application.update(boundary_geojson: {})

        expect {
          perform_enqueued_jobs
        }.not_to raise_error
      end
    end
  end
end
