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
        ActionController::Parameters.new(json_fixture("files/applications/PT-10087984.json"))
      }

      it "returns a correctly formatted proposal hash" do
        expected_geojson = params.dig("polygon", "features", 0, "geometry").to_json

        expect(parse_proposal).to eq(
          description: "\nDH Test Description",
          boundary_geojson: expected_geojson
        )
      end
    end

    context "with missing polygon" do
      let(:params) do
        fixture = ActionController::Parameters.new(json_fixture("files/applications/PT-10087984.json")).deep_dup
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
