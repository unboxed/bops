# frozen_string_literal: true

require_relative "../../../swagger_helper"

RSpec.describe BopsSubmissions::Parsers::ProposalParser do
  describe "#parse" do
    let(:local_authority) { create(:local_authority, :default) }

    let(:parse_proposal) do
      described_class.new(params, local_authority:).parse
    end

    context "with valid params" do
      let(:params) {
        json_fixture("files/applications/PT-10087984.json")
      }

      it "returns a correctly formatted proposal hash" do
        expect(parse_proposal).to eq(
          description: "\nDH Test Description",
          boundary_geojson: {"geometry" => {
                               "coordinates" => [
                                 [
                                   [
                                     [-0.116792, 51.460787],
                                     [-0.117213, 51.4607],
                                     [-0.117229, 51.46057],
                                     [-0.117112, 51.46055],
                                     [-0.117002, 51.460567],
                                     [-0.116942, 51.460605],
                                     [-0.116982, 51.460721],
                                     [-0.116752, 51.460765],
                                     [-0.116792, 51.460787]
                                   ]
                                 ]
                               ],
                               "type" => "MultiPolygon"
                             },
                             "id" => "099bc773-098d-44e9-9344-26d9e9c8c4ef",
                             "properties" => {"boundaryType" => "MY_BOUNDARY"},
                             "type" => "Feature"}
        )
      end
    end

    context "with missing polygon" do
      let(:params) do
        fixture = json_fixture("files/applications/PT-10087984.json")
        fixture["polygon"] = nil
        fixture
      end

      it "returns description and nil boundary_geojson" do
        expect(parse_proposal).to eq(
          description: "\nDH Test Description",
          boundary_geojson: nil
        )
      end
    end
  end
end
