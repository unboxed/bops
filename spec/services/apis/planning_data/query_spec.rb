# frozen_string_literal: true

require "rails_helper"

RSpec.describe Apis::PlanningData::Query do
  let(:query) { described_class.new }

  describe "#fetch" do
    context "when the request is successful" do
      context "when a valid council code reference is supplied" do
        before do
          stub_planning_data_api_request_for("BUC").to_return(planning_data_api_response(:ok, "BUC"))
        end

        it "returns buckinghamshire council's data" do
          resp = query.fetch("BUC", ["local-authority"])
          expect(resp["count"]).to eq(1)
          expect(resp["entities"][0]["reference"]).to eq("BUC")
        end
      end

      context "when an invalid council code reference is supplied" do
        before do
          stub_planning_data_api_request_for("TEST").to_return(planning_data_api_response(:ok, "TEST"))
        end

        it "returns an empty object" do
          resp = query.fetch("TEST", ["local-authority"])
          expect(resp["count"]).to eq(0)
          expect(resp["entities"]).to be_empty
        end
      end
    end
  end

  describe "#council_code" do
    context "when the request is successful" do
      context "when a valid council code reference is supplied" do
        before do
          stub_planning_data_api_request_for("BUC").to_return(planning_data_api_response(:ok, "BUC"))
          stub_planning_data_api_request_for("LBH").to_return(planning_data_api_response(:ok, "LBH"))
          stub_planning_data_api_request_for("SWK").to_return(planning_data_api_response(:ok, "SWK"))
        end

        it "returns buckinghamshire council's reference code" do
          expect(query.council_code("BUC")).to eq("BUC")
        end

        it "returns lambeth council's reference code" do
          expect(query.council_code("LBH")).to eq("LBH")
        end

        it "returns southwark council's reference code" do
          expect(query.council_code("SWK")).to eq("SWK")
        end
      end

      context "when an invalid council code reference is supplied" do
        before do
          stub_planning_data_api_request_for("TEST").to_return(planning_data_api_response(:ok, "TEST"))
        end

        it "returns nil" do
          expect(query.council_code("TEST")).to be_nil
        end
      end
    end
  end
end
