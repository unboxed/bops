# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProposalDetail do
  let(:attributes) do
    {
      question: "Test question?",
      responses: [
        {
          value: "Test response",
          metadata: {flags: ["Test flag"]}
        }
      ],
      metadata: {
        auto_answered: auto_asnwered,
        section_name: "Test portal",
        policy_refs: [
          {text: "Test ref text", url: "https://www.exampleref.com"}
        ],
        notes: "Test notes"
      }
    }.deep_stringify_keys
  end

  let(:auto_asnwered) { nil }
  let(:proposal_detail) { described_class.new(attributes, 1) }

  describe "#question" do
    it "returns question" do
      expect(proposal_detail.question).to eq("Test question?")
    end
  end

  describe "#index" do
    it "returns index" do
      expect(proposal_detail.index).to eq(1)
    end
  end

  describe "#auto_answered" do
    context "when auto_answered is blank" do
      it "returns false" do
        expect(proposal_detail.auto_answered?).to be(false)
      end
    end

    context "when auto_answered is false" do
      let(:auto_asnwered) { false }

      it "returns false" do
        expect(proposal_detail.auto_answered?).to be(false)
      end
    end

    context "when auto_answered is true" do
      let(:auto_asnwered) { true }

      it "returns false" do
        expect(proposal_detail.auto_answered?).to be(true)
      end
    end
  end

  describe "#flags" do
    it "returns array of flags" do
      expect(proposal_detail.flags).to contain_exactly("Test flag")
    end
  end

  describe "#notes" do
    it "returns notes" do
      expect(proposal_detail.notes).to eq("Test notes")
    end
  end

  describe "#policy refs" do
    it "returns array of policy refs" do
      expect(proposal_detail.policy_refs).to contain_exactly(
        {"text" => "Test ref text", "url" => "https://www.exampleref.com"}
      )
    end
  end

  describe "#section_name" do
    it "returns portal name" do
      expect(proposal_detail.section_name).to eq("Test portal")
    end
  end

  describe "#response_values" do
    it "returns array of response values" do
      expect(
        proposal_detail.response_values
      ).to contain_exactly(
        "Test response"
      )
    end
  end
end
