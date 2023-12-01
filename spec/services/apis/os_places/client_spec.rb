# frozen_string_literal: true

require "rails_helper"

RSpec.describe Apis::OsPlaces::Client, exclude_stub_any_os_places_api_request: true do
  let(:client) { described_class.new }

  before do
    Rails.configuration.os_vector_tiles_api_key = "testtest"
  end

  describe "#get" do
    before do
      stub_os_places_api_request_for("SE220HW")
    end

    it "is successful" do
      expect(
        client.get(
          "find",
          {
            maxresults: 20,
            query: "SE220HW"
          }
        ).status
      ).to eq(200)
    end
  end

  describe "#post" do
    before do
      stub_os_places_api_request_for_polygon(geojson)
    end

    let(:geojson) do
      {
        "type" => "Feature",
        "geometry" => {
          "type" => "Polygon",
          "coordinates" => [
            [
              [-0.07837477827741827, 51.49960885888714],
              [-0.0783663401899492, 51.49932756979237],
              [-0.07795182562987539, 51.49943999679809],
              [-0.07803420855642619, 51.49966559098456],
              [-0.07837477827741827, 51.49960885888714]
            ]
          ]
        },
        "properties" => nil
      }
    end

    it "is successful" do
      result = client.post(
        geojson, {
          output_srs: "EPSG:27700",
          srs: "EPSG:27700"
        }
      )

      expect(result).to contain_exactly(hash_including("ADDRESS" => "5, COXSON WAY, LONDON, SE1 2XB"),
        hash_including("ADDRESS" => "6, COXSON WAY, LONDON, SE1 2XB"))
    end
  end
end
