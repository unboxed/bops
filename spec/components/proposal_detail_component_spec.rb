# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProposalDetailComponent, type: :component do
  let(:proposal_detail) do
    OpenStruct.new(
      question: "Question 1",
      responses: [OpenStruct.new(value: "Answer 1")],
      metadata: OpenStruct.new(
        portal_name: "Group A",
        auto_answered: true
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
      let(:proposal_detail) do
        OpenStruct.new(
          question: "Question 1",
          responses: [OpenStruct.new(value: "Answer 1")],
          metadata: OpenStruct.new(
            portal_name: "Group A"
          ),
          number: 1
        )
      end

      it "returns false" do
        expect(proposal_detail_component.send(:auto_answered?)).to eq(false)
      end
    end
  end
end
