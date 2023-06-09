# frozen_string_literal: true

require "rails_helper"

RSpec.describe Apis::PlanningData::Query do
  let(:query) { described_class.new }

  describe "#fetch" do
    context "when the request is successful" do
      context "when a valid council code reference is supplied" do
        before do
          stub_planning_data_api_request_for("BUC").to_return(planning_data_api_response(:ok, "BUC"))
          stub_planning_data_api_request_for("LBH").to_return(planning_data_api_response(:ok, "LBH"))
          stub_planning_data_api_request_for("SWK").to_return(planning_data_api_response(:ok, "SWK"))
        end

        it "returns buckinghamshire council's reference code" do
          expect(query.fetch("BUC", "local-authority")).to eq("BUC")
        end

        it "returns lambeth council's reference code" do
          expect(query.fetch("LBH", "local-authority")).to eq("LBH")
        end

        it "returns southwark council's reference code" do
          expect(query.fetch("SWK", "local-authority")).to eq("SWK")
        end
      end

      context "when an invalid council code reference is supplied" do
        before do
          stub_planning_data_api_request_for("TEST").to_return(planning_data_api_response(:ok, "TEST"))
        end

        it "returns nil" do
          expect(query.fetch("TEST", "local-authority")).to be_nil
        end
      end
    end
  end
end
