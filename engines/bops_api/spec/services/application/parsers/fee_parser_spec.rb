# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::Application::Parsers::FeeParser do
  describe "#parse" do
    let(:local_authority) { create(:local_authority, :default) }

    let(:parse_fee) do
      described_class.new(params, local_authority:).parse
    end

    context "with valid params" do
      let(:params) {
        ActionController::Parameters.new(
          JSON.parse(file_fixture("v2/valid_planning_permission.json").read)
        )[:data][:application][:fee]
      }

      it "returns a correctly formatted applicant hash" do
        expect(parse_fee).to eq(
          payment_amount: 206,
          payment_reference: "sandbox-ref-456"
        )
      end
    end

    context "with missing input params" do
      let(:params) { {} }

      it "returns an empty hash" do
        expect(parse_fee).to eq({})
      end
    end
  end
end
