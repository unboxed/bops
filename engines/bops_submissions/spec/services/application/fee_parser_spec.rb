# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsSubmissions::Parsers::FeeParser do
  describe "#parse" do

    let(:parse_fee) do
      described_class.new(params).parse
    end

    context "with valid params" do
      let(:params) {
        ActionController::Parameters.new(
          JSON.parse(file_fixture("v2/valid_planning_portal_planning_permission.json").read)
        )["feeCalculationSummary"]
      }

      it "returns a correctly formatted applicant hash" do
        expect(parse_fee).to eq(
          payment_amount: 0.00,
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