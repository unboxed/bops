# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::Application::Parsers::AgentParser do
  describe "#parse" do
    let(:local_authority) { create(:local_authority, :default) }

    let(:parse_agent) do
      described_class.new(params, local_authority:).parse
    end

    context "with valid params" do
      let(:params) {
        ActionController::Parameters.new(
          JSON.parse(file_fixture("v2/valid_planning_permission.json").read)
        )[:data][:applicant][:agent]
      }

      it "returns a correctly formatted agent hash" do
        expect(parse_agent).to eq(
          agent_first_name: "Ziggy",
          agent_last_name: "Stardust",
          agent_email: "ziggy@example.com",
          agent_phone: "01100 0110 0011"
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
