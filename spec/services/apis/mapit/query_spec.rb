# frozen_string_literal: true

require "rails_helper"

RSpec.describe Apis::Mapit::Query do
  let(:query) { described_class.new }

  describe "#fetch" do
    context "when the request is successful" do
      context "when a valid postcode is supplied" do
        before do
          stub_mapit_api_request_for("SE220HW").to_return(mapit_api_response(:ok, "SE220HW"))
          stub_mapit_api_request_for("HP92HA").to_return(mapit_api_response(:ok, "HP92HA"))
        end

        it "returns an array with ward type, ward name and parish name (type NPC)" do
          expect(query.fetch("SE220HW")).to eq(["London borough ward", "Dulwich Hill", "Southwark, unparished area"])
        end

        it "returns an array with ward type, ward name and parish name (type CPC)" do
          expect(query.fetch("HP92HA")).to eq(["Unitary Authority ward (UTW)", "Beaconsfield ward", "Beaconsfield"])
        end
      end
    end

    context "when the request is unsuccessful" do
      context "when a postcode is not found" do
        before do
          stub_mapit_api_request_for("SE110H9").to_return(mapit_api_response(:not_found, "no_result"))
        end

        it "returns an empty array" do
          expect(query.fetch("SE110H9")).to eq([])
        end
      end

      context "when the API does not respond" do
        before do
          stub_mapit_api_request_for("SE110H9").to_timeout
        end

        it "returns an empty array" do
          expect(query.fetch("SE110H9")).to eq([])
        end
      end

      context "when the API is returning an internal server error" do
        before do
          stub_mapit_api_request_for("SE110H9").to_return(mapit_api_response(:internal_server_error))
        end

        it "returns an empty array" do
          expect(query.fetch("SE110H9")).to eq([])
        end
      end

      context "when the API can't find the resource" do
        before do
          stub_mapit_api_request_for("SE110H9").to_return(mapit_api_response(:not_acceptable))
        end

        it "returns an empty array" do
          expect(query.fetch("SE110H9")).to eq([])
        end
      end
    end
  end
end
