# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlanningDataHelper do
  describe ".planning_data_map_url" do
    let(:planning_application) { create(:planning_application) }
    let(:url) { planning_data_map_url(datasets, planning_application) }

    context "when there are datasets" do
      let(:datasets) { ["tree-preservation-zone", "listed-building", "listed-building-outline"] }

      it "generates the map url with query parameters and centers on the planning application" do
        expect(url).to eq(
          "https://www.planning.data.gov.uk/map/?dataset=tree-preservation-zone&dataset=listed-building&dataset=listed-building-outline##{"#{planning_application.latitude},#{planning_application.longitude},17"}"
        )
      end
    end

    context "when there are no datasets" do
      let(:datasets) { [] }

      it "generates the map url and centers on the planning application" do
        expect(url).to eq("https://www.planning.data.gov.uk/map/##{"#{planning_application.latitude},#{planning_application.longitude},17"}")
      end
    end
  end

  describe ".planning_data_entity_url" do
    let(:url) { planning_data_entity_url(entity) }
    let(:entity) { 12345 }

    it "generates the entity url" do
      expect(url).to eq("https://www.planning.data.gov.uk/entity/12345")
    end
  end
end
