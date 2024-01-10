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
    context "when total addresses found is less than 100" do
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

        expect(result).to eq(["5, COXSON WAY, LONDON, SE1 2XB", "6, COXSON WAY, LONDON, SE1 2XB"])
      end
    end

    context "when total addresses found is more than 100" do
      before do
        stub_os_places_api_request_for_polygon(geojson, "polygon_search_more_than_100_addresses_offset_0")
        stub_os_places_api_request_for_polygon(geojson, "polygon_search_more_than_100_addresses_offset_100", 100)
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

      it "returns all the addresses with 2 API requests made" do
        expect(Faraday).to receive(:new).once.and_call_original
        expect_any_instance_of(Faraday::Connection).to receive(:post).twice.and_call_original

        result = client.post(
          geojson, {
            output_srs: "EPSG:27700",
            srs: "EPSG:27700"
          }
        )

        expect(result.length).to eq(103)
        expect(result).to include(
          "1, Example Street, LONDON, SE1 2XB", "2, Example Street, LONDON, SE1 2XB", "102, Example Street, LONDON, SE1 2XB", "103, Example Street, LONDON, SE1 2XB"
        )
      end
    end
  end
end
