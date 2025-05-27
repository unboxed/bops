# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsSubmissions::Parsers::AgentParser do
  describe "#parse" do
    # let(:local_authority) { create(:local_authority, :default) }

    let(:parse_agent) do
      described_class.new(params).parse
    end

    context "with valid params" do
      let(:params) {
        ActionController::Parameters.new(
          JSON.parse(file_fixture("v2/valid_planning_portal_planning_permission.json").read)
        )["applicationData"]["agent"]
      }

      it "returns a correctly formatted agent hash" do
        expect(parse_agent).to eq(
          agent_first_name: "Daleel",
          agent_last_name: "Hagy",
          agent_email: "dhagy1@lambeth.gov.uk",
          agent_phone: "02079260135"
        )
      end
    end

    context "with missing input params" do
      let(:params) { {} }

      it "returns an empty hash" do
        expect(parse_agent).to eq({})
      end
    end
  end
end
