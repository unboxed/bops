# frozen_string_literal: true

require "rails_helper"

RSpec.shared_examples "ProposalDetailsGroupable" do
  let(:portal_name) { "unformatted name" }

  let(:proposal_detail1) do
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

  let(:proposal_detail2) do
    OpenStruct.new(
      question: "Question 2",
      responses: [OpenStruct.new(value: "Answer 2")],
      metadata: OpenStruct.new(portal_name: "Group A"),
      number: 2
    )
  end

  let(:group) do
    OpenStruct.new(
      portal_name: portal_name,
      proposal_details: [proposal_detail1, proposal_detail2]
    )
  end

  let(:subject) { described_class.new(group: group) }

  describe "#auto_answered?" do
    context "when not all proposal_details auto answered" do
      it "returns false" do
        expect(subject.send(:auto_answered?)).to eq(false)
      end
    end

    context "when all proposal_details auto answered" do
      let(:proposal_detail2) do
        OpenStruct.new(
          question: "Question 2",
          responses: [OpenStruct.new(value: "Answer 2")],
          metadata: OpenStruct.new(
            portal_name: "Group A",
            auto_answered: true
          ),
          number: 2
        )
      end

      it "returns true" do
        expect(subject.send(:auto_answered?)).to eq(true)
      end
    end
  end

  describe "#id" do
    it "returns formatted string" do
      expect(subject.send(:id)).to eq("unformattedname")
    end

    context "when portal_name is '_root'" do
      let(:portal_name) { "_root" }

      it "returns 'main'" do
        expect(subject.send(:id)).to eq("main")
      end
    end

    context "when there is no portal_name" do
      let(:portal_name) { nil }

      it "returns 'other'" do
        expect(subject.send(:id)).to eq("other")
      end
    end
  end

  describe "#title" do
    it "returns formatted string" do
      expect(subject.send(:title)).to eq("Unformatted name")
    end

    context "when portal_name is '_root'" do
      let(:portal_name) { "_root" }

      it "returns 'Main'" do
        expect(subject.send(:title)).to eq("Main")
      end
    end

    context "when there is no portal_name" do
      let(:portal_name) { nil }

      it "returns 'other'" do
        expect(subject.send(:title)).to eq("Other")
      end
    end
  end
end
