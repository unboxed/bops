# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::Filters::Comments::SentimentFilter do
  let(:local_authority) { create(:local_authority) }
  let(:planning_application) { create(:planning_application, local_authority:) }
  let(:consultation) { create(:consultation, planning_application:) }
  let(:neighbour) { create(:neighbour, consultation:) }
  let(:filter) { described_class.new(NeighbourResponse) }

  describe "#applicable?" do
    it "returns true when sentiment param is present" do
      expect(filter.applicable?({sentiment: ["supportive"]})).to be true
    end

    it "returns false when sentiment param is blank" do
      expect(filter.applicable?({})).to be false
    end

    it "returns false when sentiment param is empty array" do
      expect(filter.applicable?({sentiment: []})).to be false
    end
  end

  describe "#apply" do
    let!(:supportive_response) do
      create(:neighbour_response, neighbour:, summary_tag: "supportive")
    end
    let!(:neutral_response) do
      create(:neighbour_response, neighbour:, summary_tag: "neutral")
    end
    let!(:objection_response) do
      create(:neighbour_response, neighbour:, summary_tag: "objection")
    end

    let(:scope) { NeighbourResponse.all }

    context "with single sentiment" do
      it "filters by supportive sentiment" do
        result = filter.apply(scope, {sentiment: ["supportive"]})

        expect(result).to include(supportive_response)
        expect(result).not_to include(neutral_response, objection_response)
      end

      it "filters by neutral sentiment" do
        result = filter.apply(scope, {sentiment: ["neutral"]})

        expect(result).to include(neutral_response)
        expect(result).not_to include(supportive_response, objection_response)
      end

      it "filters by objection sentiment" do
        result = filter.apply(scope, {sentiment: ["objection"]})

        expect(result).to include(objection_response)
        expect(result).not_to include(supportive_response, neutral_response)
      end
    end

    context "with multiple sentiments" do
      it "filters by multiple sentiments" do
        result = filter.apply(scope, {sentiment: ["supportive", "neutral"]})

        expect(result).to include(supportive_response, neutral_response)
        expect(result).not_to include(objection_response)
      end
    end

    context "with invalid sentiment" do
      it "raises ArgumentError for single invalid sentiment" do
        expect {
          filter.apply(scope, {sentiment: ["invalid"]})
        }.to raise_error(ArgumentError, /Invalid sentiment\(s\): invalid/)
      end

      it "raises ArgumentError listing all invalid sentiments" do
        expect {
          filter.apply(scope, {sentiment: ["invalid1", "invalid2"]})
        }.to raise_error(ArgumentError, /Invalid sentiment\(s\): invalid1, invalid2/)
      end

      it "includes allowed values in error message" do
        expect {
          filter.apply(scope, {sentiment: ["invalid"]})
        }.to raise_error(ArgumentError, /Allowed values:.*supportive/)
      end
    end
  end

  describe "with Consultee::Response model" do
    let(:filter) { described_class.new(Consultee::Response) }
    let!(:consultation) { create(:consultation, :started) }
    let!(:consultee) { create(:consultee, :internal, :consulted, consultation:) }

    let!(:approved_response) do
      create(:consultee_response, consultee:, summary_tag: "approved")
    end
    let!(:objected_response) do
      create(:consultee_response, consultee:, summary_tag: "objected")
    end

    let(:scope) { Consultee::Response.all }

    it "filters by approved sentiment" do
      result = filter.apply(scope, {sentiment: ["approved"]})

      expect(result).to include(approved_response)
      expect(result).not_to include(objected_response)
    end

    it "handles camelCase sentiment values" do
      amendments_response = create(:consultee_response, consultee:, summary_tag: "amendments_needed")

      result = filter.apply(scope, {sentiment: ["amendmentsNeeded"]})

      expect(result).to include(amendments_response)
    end
  end
end
