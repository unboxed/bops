# frozen_string_literal: true

require_relative "../../../swagger_helper"

RSpec.describe BopsSubmissions::Parsers::FeeParser do
  describe "#parse" do
    let(:local_authority) { create(:local_authority, :default) }

    let(:parse_fee) do
      described_class.new(params, source: "Planning Portal", local_authority:).parse
    end

    context "with valid params" do
      let(:params) {
        json_fixture_submissions("files/applications/PT-10087984.json")["feeCalculationSummary"]
      }

      it "returns a correctly formatted fee hash" do
        expect(parse_fee).to eq(
          payment_amount: 0.0,
          payment_reference: nil
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
