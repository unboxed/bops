# frozen_string_literal: true

require "rails_helper"

RSpec.describe Apis::PlanX::Query do
  before do
    stub_request(:get,
      "https://api.editor.planx.uk/gis/opensystemslab").with(
        query: hash_including({geom: /POLYGON/})
      ).to_return(body: {}.to_json)
  end

  describe "#request" do
    it "is successful" do
      geojson = {"type" => "Polygon", "coordinates" => [[[-0.07629275321961124, 51.48596289289142], [-0.07630616426468570, 51.48591028066045], [-0.07555112242699404, 51.48584764697301], [-0.07554173469544191, 51.48590192950712], [-0.07629275321961124, 51.48596289289142]]]}
      response = described_class.request(geojson:)
      expect(response[:response].status).to eq(200)
    end
  end

  describe "#query" do
    it "is successful" do
      geojson = {"type" => "Polygon", "coordinates" => [[[-0.07629275321961124, 51.48596289289142], [-0.07630616426468570, 51.48591028066045], [-0.07555112242699404, 51.48584764697301], [-0.07554173469544191, 51.48590192950712], [-0.07629275321961124, 51.48596289289142]]]}
      response = described_class.query(geojson:)
      expect { response }.not_to raise_error
    end
  end
end
