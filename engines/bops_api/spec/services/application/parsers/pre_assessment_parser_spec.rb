# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::Application::Parsers::PreAssessmentParser do
  describe "#parse" do
    let(:local_authority) { create(:local_authority, :default) }

    let(:parse_pre_assessment) do
      described_class.new(params, local_authority:).parse
    end

    context "with valid params" do
      let(:params) {
        ActionController::Parameters.new(
          JSON.parse(file_fixture("v2/valid_prior_approval.json").read)
        )[:preAssessment]
      }

      it "returns a correctly formatted applicant hash" do
        expect(parse_pre_assessment).to eq(
          result_heading: "Planning permission / Prior approval",
          result_description: "It looks like the proposed changes do not require planning permission, however the applicant must apply for Prior Approval before proceeding."
        )
      end
    end

    context "with missing input params" do
      let(:params) { [] }

      it "returns an empty hash" do
        expect(parse_pre_assessment).to eq({})
      end
    end
  end
end
