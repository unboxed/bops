# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::Application::Parsers::SubmissionParser do
  describe "#parse" do
    let(:local_authority) { create(:local_authority, :default) }

    let(:parse_submission) do
      described_class.new(params, local_authority:).parse
    end

    context "with valid params" do
      let(:params) {
        ActionController::Parameters.new(
          JSON.parse(file_fixture("v2/valid_planning_permission.json").read)
        )
      }

      it "returns a correctly formatted submission hash" do
        expect(parse_submission).to eq(
          session_id: "81bcaa0f-baf5-4573-ba0a-ea868c573faf",
          params_v2: params
        )
      end
    end
  end
end
