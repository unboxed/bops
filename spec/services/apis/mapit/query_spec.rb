# frozen_string_literal: true

require "rails_helper"

RSpec.describe Apis::Mapit::Query do
  let(:query) { described_class.new }

  describe "#fetch" do
    context "when the request is successful" do
      context "when a valid postcode is supplied" do
        before do
          stub_api_request_for("SE220HW").to_return(api_response(:ok, "SE220HW"))
        end

        it "returns an array with ward type and ward name" do
          expect(query.fetch("SE220HW")).to eq(["London borough ward", "Dulwich Hill"])
        end
      end
    end

    context "when the request is unsuccessful" do
      context "when a postcode is not found" do
        before do
          stub_api_request_for("SE110H9").to_return(api_response(:not_found, "no_result"))
        end

        it "returns an empty array" do
          expect(query.fetch("SE110H9")).to eq([])
        end
      end

      context "when the API does not respond" do
        before do
          stub_api_request_for("SE110H9").to_timeout
        end

        it "returns an empty array" do
          expect(query.fetch("SE110H9")).to eq([])
        end
      end

      context "when the API is returning an internal server error" do
        before do
          stub_api_request_for("SE110H9").to_return(api_response(:internal_server_error))
        end

        it "returns an empty array" do
          expect(query.fetch("SE110H9")).to eq([])
        end
      end

      context "when the API can't find the resource" do
        before do
          stub_api_request_for("SE110H9").to_return(api_response(:not_acceptable))
        end

        it "returns an empty array" do
          expect(query.fetch("SE110H9")).to eq([])
        end
      end
    end
  end
end
