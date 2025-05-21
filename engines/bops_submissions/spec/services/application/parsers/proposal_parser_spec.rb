# frozen_string_literal: true

require "rails_helper"
require "pry"

RSpec.describe BopsSubmissions::Parsers::ProposalParser do
  describe "#parse" do
    let(:local_authority) { create(:local_authority, :default) }

    let(:parse_proposal) do
      described_class.new(params, local_authority:).parse
    end

    context "with valid params" do
      let(:params) {
        ActionController::Parameters.new(
          JSON.parse(file_fixture("v2/valid_planning_portal_planning_permission.json").read)
        )
      }

      it "returns a correctly formatted proposal hash" do
        # binding.pry
        expect(parse_proposal).to eq(
          description: "\nDH Test Description",
          boundary_geojson: "{\"type\":\"MultiPolygon\",\"coordinates\":[[[[530926,175216.21],[530897.02,175205.71],[530896.2343587935,175191.29044591202],[530904.4400000001,175189.18999999997],[530912,175191.28999999998],[530916.06,175195.62999999998],[530912.9800000001,175208.50999999998],[530928.8,175213.83],[530926,175216.21]]]]}"
        )
      end
    end
  end
end
