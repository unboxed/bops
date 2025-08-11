# frozen_string_literal: true

require "rails_helper"

RSpec.describe Enforcement do
  let(:wkt) do
    <<~WKT
      GEOMETRYCOLLECTION (
        POLYGON (
          (
            0.506110 51.387327,
            0.506150 51.387279,
            0.506253 51.387315,
            0.506215 51.387360,
            0.506110 51.387327
          )
        )
      )
    WKT
  end

  let(:factory) { RGeo::Geographic.spherical_factory(srid: 4326) }
  let(:boundary) { factory.parse_wkt(wkt) }

  describe "#boundary_geojson" do
    context "when the boundary is not present" do
      let(:enforcement) { described_class.new }

      it "returns nil for the boundary" do
        expect(enforcement.boundary_geojson).to be_nil
      end
    end

    context "when the boundary is present" do
      let(:enforcement) { described_class.new(boundary:) }

      let(:geojson) do
        {
          "type" => "FeatureCollection",
          "features" => [
            {
              "type" => "Feature",
              "properties" => {},
              "geometry" => {
                "coordinates" => [
                  [
                    [0.506110, 51.387327],
                    [0.506150, 51.387279],
                    [0.506253, 51.387315],
                    [0.506215, 51.387360],
                    [0.506110, 51.387327]
                  ]
                ],
                "type" => "Polygon"
              }
            }
          ]
        }
      end

      it "returns the boundary as GeoJSON" do
        expect(enforcement.boundary_geojson).to match(geojson)
      end
    end
  end

  describe "#boundary_geojson=" do
    let(:enforcement) { described_class.new }

    context "when setting the boundary using invalid GeoJSON" do
      it "raises an error" do
        expect {
          enforcement.boundary_geojson = "Not GeoJSON"
        }.to raise_error(JSON::ParserError, /unexpected token/)
      end
    end

    context "when setting the boundary using a FeatureCollection" do
      let(:geojson) do
        <<~JSON
          {
            "type": "FeatureCollection",
            "features": [
              {
                "type": "Feature",
                "properties": {},
                "geometry": {
                  "coordinates": [
                    [
                      [0.506110, 51.387327],
                      [0.506150, 51.387279],
                      [0.506253, 51.387315],
                      [0.506215, 51.387360],
                      [0.506110, 51.387327]
                    ]
                  ],
                  "type": "Polygon"
                }
              }
            ]
          }
        JSON
      end

      it "sets the boundary from the GeoJSON" do
        expect {
          enforcement.boundary_geojson = geojson
        }.to change {
          enforcement.boundary
        }.from(nil).to(boundary)
      end
    end

    context "when setting the boundary using a Feature" do
      let(:geojson) do
        <<~JSON
          {
            "type": "Feature",
            "properties": {},
            "geometry": {
              "coordinates": [
                [
                  [0.506110, 51.387327],
                  [0.506150, 51.387279],
                  [0.506253, 51.387315],
                  [0.506215, 51.387360],
                  [0.506110, 51.387327]
                ]
              ],
              "type": "Polygon"
            }
          }
        JSON
      end

      it "sets the boundary from the GeoJSON" do
        expect {
          enforcement.boundary_geojson = geojson
        }.to change {
          enforcement.boundary
        }.from(nil).to(boundary)
      end
    end
  end
end
