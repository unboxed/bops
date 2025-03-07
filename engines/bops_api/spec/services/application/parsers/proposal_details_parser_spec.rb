# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::Application::Parsers::ProposalDetailsParser do
  describe "#parse" do
    let(:local_authority) { create(:local_authority, :default) }

    let(:parse_proposal_details) do
      described_class.new(params, local_authority:).parse
    end

    context "with valid params" do
      let(:params) {
        ActionController::Parameters.new(
          JSON.parse(file_fixture("v2/valid_planning_permission.json").read)
        )[:responses]
      }

      it "returns a correctly formatted proposal_details hash" do
        expect(parse_proposal_details).to eq(
          proposal_details: params
        )
      end
    end
  end
end
