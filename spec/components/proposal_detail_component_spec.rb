# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProposalDetailComponent, type: :component do
  let(:auto_answered) { true }

  let(:policy_refs) do
    [
      OpenStruct.new(url: "www.example.com"),
      OpenStruct.new(text: "Article 1")
    ]
  end

  let(:proposal_detail) do
    OpenStruct.new(
      question: "Question 1",
      responses: [
        OpenStruct.new(value: "Answer 1"),
        OpenStruct.new(value: "Answer 2")
      ],
      metadata: OpenStruct.new(
        portal_name: "Group A",
        auto_answered: auto_answered,
        policy_refs: policy_refs
      ),
      number: 1
    )
  end

  let(:proposal_detail_component) do
    described_class.new(proposal_detail: proposal_detail)
  end

  describe "#auto_answered?" do
    context "when question was auto answered" do
      it "returns true" do
        expect(proposal_detail_component.send(:auto_answered?)).to eq(true)
      end
    end

    context "when question was not auto answered" do
      let(:auto_answered) { false }

      it "returns false" do
        expect(proposal_detail_component.send(:auto_answered?)).to eq(false)
      end
    end
  end

  describe "#formatted_policy_refs" do
    it "returns a formatted string" do
      expect(
        proposal_detail_component.send(:formatted_policy_refs)
      ).to eq(
        "<a class=\"govuk-link\" href=\"www.example.com\">www.example.com</a>, Article 1"
      )
    end

    context "when policy refs is not present" do
      let(:policy_refs) { nil }

      it "returns nil" do
        expect(
          proposal_detail_component.send(:formatted_policy_refs)
        ).to eq(
          nil
        )
      end
    end
  end
end
