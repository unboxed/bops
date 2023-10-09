# frozen_string_literal: true

require "rails_helper"

RSpec.describe NeighbourResponse do
  describe "validations" do
    subject(:neighbour_response) { described_class.new }

    describe "#received_at" do
      it "validates presence" do
        expect { neighbour_response.valid? }.to change { neighbour_response.errors[:received_at] }.to ["can't be blank"]
      end
    end

    describe "#response" do
      it "validates presence" do
        expect { neighbour_response.valid? }.to change { neighbour_response.errors[:response] }.to ["can't be blank"]
      end
    end

    describe "#name" do
      it "validates presence" do
        expect { neighbour_response.valid? }.to change { neighbour_response.errors[:name] }.to ["can't be blank"]
      end
    end

    describe "#neighbour" do
      it "validates presence" do
        expect { neighbour_response.valid? }.to change { neighbour_response.errors[:neighbour] }.to ["must exist"]
      end
    end

    describe "#consultation" do
      it "validates presence" do
        expect { neighbour_response.valid? }.to change { neighbour_response.errors[:consultation] }.to ["must exist"]
      end
    end
  end

  describe "scopes" do
    describe ".redacted" do
      let!(:neighbour_responses1) { create(:neighbour_response, redacted_response: "") }
      let!(:neighbour_responses2) { create(:neighbour_response, redacted_response: "redacted") }
      let!(:neighbour_responses3) { create(:neighbour_response, redacted_response: "redacted") }

      it "returns neighbour_responses with redactions" do
        expect(described_class.redacted).to eq([neighbour_responses2, neighbour_responses3])
      end
    end

    describe ".objection" do
      let!(:neighbour_responses1) { create(:neighbour_response, summary_tag: "supportive") }
      let!(:neighbour_responses2) { create(:neighbour_response, summary_tag: "neutral") }
      let!(:neighbour_responses3) { create(:neighbour_response, summary_tag: "objection") }

      it "returns neighbour_responses with redactions" do
        expect(described_class.objection).to eq([neighbour_responses3])
      end
    end
  end

  describe "#response" do
    let!(:neighbour_response) { create(:neighbour_response, response: "A response") }

    it "response is a readonly attribute" do
      neighbour_response.update(response: "A new response")

      expect(neighbour_response.reload.response).to eq("A response")
    end
  end
end
