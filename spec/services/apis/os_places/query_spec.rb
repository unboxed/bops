# frozen_string_literal: true

require "rails_helper"

RSpec.describe Apis::OsPlaces::Query, exclude_stub_any_os_places_api_request: true do
  let(:query) { described_class.new }

  before do
    Rails.configuration.os_vector_tiles_api_key = "testtest"
  end

  describe ".find_addresses" do
    before do
      stub_os_places_api_request_for("SE220HW")
    end

    it "initializes a Client object and invokes #find_addresses" do
      expect_any_instance_of(
        Apis::OsPlaces::Client
      ).to receive(:get).with(
        "find", {
          maxresults: 20,
          query: "SE220HW"
        }
      ).and_call_original

      described_class.new.find_addresses("SE220HW")
    end

    context "when Faraday::Error is raised" do
      before do
        allow_any_instance_of(Apis::OsPlaces::Client).to receive(:get).and_raise(Faraday::Error.new("Test error"))
      end

      it "sends exception to Appsignal" do
        expect(Appsignal).to receive(:send_exception).with(instance_of(Faraday::Error))

        result = described_class.new.find_addresses(query)
        expect(result).to eq([])
      end
    end
  end

  describe ".find_addresses_by_polygon" do
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
    let(:uprn) { "100021892955" }

    it "initializes a Client object and invokes #find_addresses_by_polygon" do
      expect_any_instance_of(
        Apis::OsPlaces::Client
      ).to receive(:post).with(
        geojson,
        {
          output_srs: "EPSG:27700",
          srs: "EPSG:27700"
        },
        uprn
      ).and_call_original

      described_class.new.find_addresses_by_polygon(geojson, uprn)
    end

    context "when Faraday::Error is raised" do
      before do
        allow_any_instance_of(Apis::OsPlaces::Client).to receive(:post).and_raise(Faraday::Error.new("Test error"))
      end

      it "sends exception to Appsignal" do
        expect(Appsignal).to receive(:send_exception).with(instance_of(Faraday::Error))

        result = described_class.new.find_addresses_by_polygon(geojson, uprn)
        expect(result).to eq([])
      end
    end
  end
end
