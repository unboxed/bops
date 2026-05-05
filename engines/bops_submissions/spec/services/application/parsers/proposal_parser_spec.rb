# frozen_string_literal: true

require_relative "../../../swagger_helper"

RSpec.describe BopsSubmissions::Parsers::ProposalParser do
  describe "#parse" do
    let(:local_authority) { create(:local_authority, :default) }

    let(:parse_proposal) do
      described_class.new(params, source: "Planning Portal", local_authority:).parse
    end

    context "with valid params" do
      let(:application_file) { json_fixture_submissions("files/applications/PT-10087984.json") }
      let(:site_location_file) { json_fixture_submissions("SiteLocationWGS84.geojson") }

      let(:params) {
        application_file.merge("polygon" => site_location_file)
      }

      it "returns a correctly formatted proposal hash" do
        expect(parse_proposal).to eq(
          description: "\nDH Test Description",
          boundary_geojson: {
            "features" => [
              {
                "geometry" => {
                  "coordinates" => [
                    [
                      [
                        [-0.11486488, 51.46137222],
                        [-0.11510252, 51.46131714],
                        [-0.11511232, 51.46130650],
                        [-0.11507089, 51.46119388],
                        [-0.11483910, 51.46122927],
                        [-0.11483654, 51.46122158],
                        [-0.11453008, 51.46126971],
                        [-0.11459268, 51.46141011],
                        [-0.11486488, 51.46137222]
                      ]
                    ]
                  ],
                  "type" => "MultiPolygon"
                },
                "id" => "a79d0fa9-5a89-4be4-a411-756d5e382285",
                "properties" => {
                  "boundaryType" => "MY_BOUNDARY"
                },
                "type" => "Feature"
              }
            ],
            "type" => "FeatureCollection"
          }
        )
      end
    end

    context "with missing polygon" do
      let(:application_file) { json_fixture_submissions("files/applications/PT-10087984.json") }

      let(:params) {
        application_file.merge("polygon" => nil)
      }

      it "returns description and nil boundary_geojson" do
        expect(parse_proposal).to eq(
          description: "\nDH Test Description",
          boundary_geojson: nil
        )
      end
    end
  end
end
