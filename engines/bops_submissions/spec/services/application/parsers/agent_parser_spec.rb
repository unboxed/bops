# frozen_string_literal: true

require_relative "../../../swagger_helper"

RSpec.describe BopsSubmissions::Parsers::AgentParser do
  describe "#parse" do
    let(:local_authority) { create(:local_authority, :default) }

    let(:parse_agent) do
      described_class.new(params, source: "Planning Portal", local_authority:).parse
    end

    context "with valid params" do
      let(:params) {
        json_fixture_submissions("files/applications/PT-10087984.json")["applicationData"]["agent"]
      }

      it "returns a correctly formatted agent hash" do
        expect(parse_agent).to eq(
          agent_first_name: "Bob",
          agent_last_name: "Smith",
          agent_email: "test@lambeth.gov.uk",
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
