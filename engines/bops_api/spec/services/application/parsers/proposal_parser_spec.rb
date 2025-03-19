# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::Application::Parsers::ProposalParser do
  describe "#parse" do
    let(:local_authority) { create(:local_authority, :default) }

    let(:parse_proposal) do
      described_class.new(params, local_authority:).parse
    end

    context "with valid params" do
      let(:params) {
        ActionController::Parameters.new(
          JSON.parse(file_fixture("v2/valid_planning_permission.json").read)
        )[:data][:proposal]
      }

      it "returns a correctly formatted proposal hash" do
        expect(parse_proposal).to eq(
          description: "Roof extension to the rear of the property, incorporating starship launchpad.",
          boundary_geojson: "{\"type\":\"Feature\",\"geometry\":{\"type\":\"Polygon\",\"coordinates\":[[[-0.1186569035053321,51.465703531871384],[-0.1185938715934822,51.465724418998775],[-0.1184195280075143,51.46552473766957],[-0.11848390102387167,51.4655038504508],[-0.1186569035053321,51.465703531871384]]]},\"properties\":null}"
        )
      end
    end
  end
end
