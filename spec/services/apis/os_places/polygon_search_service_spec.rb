# frozen_string_literal: true

require "rails_helper"

RSpec.describe Apis::OsPlaces::PolygonSearchService, exclude_stub_any_os_places_api_request: true do
  before do
    Rails.configuration.os_vector_tiles_api_key = "testtest"
  end

  describe "#call" do
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
    let(:params) {
      {
        output_srs: "EPSG:27700",
        srs: "EPSG:27700",
        key: Rails.configuration.os_vector_tiles_api_key
      }
    }
    let(:uprn) { "100021892955" }
    let(:data) { described_class.new(geojson, params, uprn).call }
    let(:addresses) { data[:addresses] }
    let(:total_results) { data[:total_results] }

    context "when total addresses found is less than 100" do
      before do
        stub_os_places_api_request_for_polygon(geojson)
      end

      it "returns all the addresses with one API request" do
        expect(addresses).to eq(["5, COXSON WAY, LONDON, SE1 2XB", "6, COXSON WAY, LONDON, SE1 2XB"])
        expect(total_results).to eq(2)
      end
    end

    context "when total addresses found is more than 100" do
      before do
        stub_os_places_api_request_for_polygon(geojson, "polygon_search_more_than_100_addresses_offset_0")
        stub_os_places_api_request_for_polygon(geojson, "polygon_search_more_than_100_addresses_offset_100", 100)
      end

      it "returns all the addresses with two API requests" do
        expect(Faraday).to receive(:new).once.and_call_original
        expect_any_instance_of(Faraday::Connection).to receive(:post).twice.and_call_original

        expect(addresses.length).to eq(103)
        expect(addresses).to include(
          "1, Example Street, LONDON, SE1 2XB", "2, Example Street, LONDON, SE1 2XB", "102, Example Street, LONDON, SE1 2XB", "103, Example Street, LONDON, SE1 2XB"
        )
        expect(total_results).to eq(103)
      end
    end

    context "when site address uprn is included in the search results" do
      let(:uprn) { "200003357029" }

      before do
        stub_os_places_api_request_for_polygon(geojson)
      end

      it "excludes this address" do
        expect(total_results).to eq(1)
        expect(addresses.length).to eq(1)
        expect(addresses).to eq(["6, COXSON WAY, LONDON, SE1 2XB"])
      end
    end
  end
end
