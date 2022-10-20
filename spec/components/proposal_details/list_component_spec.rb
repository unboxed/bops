# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProposalDetails::ListComponent, type: :component do
  describe "#groups" do
    let(:proposal_details) do
      [
        {
          question: "Question 1",
          responses: [{ value: "Answer 1" }],
          metadata: { portal_name: "Group A", auto_answered: true }
        },
        {
          question: "Question 2",
          responses: [{ value: "Answer 2" }],
          metadata: { portal_name: "Group A" }
        },
        {
          question: "Question 3",
          responses: [{ value: "Answer 3" }],
          metadata: { portal_name: "Group B", auto_answered: true }
        },
        {
          question: "Question 4",
          responses: [{ value: "Answer 4" }],
          metadata: { portal_name: "Group C" }
        }
      ].to_json
    end

    let(:planning_application) do
      create(:planning_application, proposal_details: proposal_details)
    end

    let(:list_component) do
      described_class.new(
        proposal_details: planning_application.proposal_details
      )
    end

    it "returns numbered proposal details grouped by portal name" do
      expect(list_component.send(:groups)).to eq(
        [
          OpenStruct.new(
            portal_name: "Group A",
            proposal_details: [
              OpenStruct.new(
                question: "Question 1",
                responses: [OpenStruct.new(value: "Answer 1")],
                metadata: OpenStruct.new(
                  portal_name: "Group A",
                  auto_answered: true
                ),
                number: 1
              ),
              OpenStruct.new(
                question: "Question 2",
                responses: [OpenStruct.new(value: "Answer 2")],
                metadata: OpenStruct.new(portal_name: "Group A"),
                number: 2
              )
            ]
          ),
          OpenStruct.new(
            portal_name: "Group B",
            proposal_details: [
              OpenStruct.new(
                question: "Question 3",
                responses: [OpenStruct.new(value: "Answer 3")],
                metadata: OpenStruct.new(
                  portal_name: "Group B",
                  auto_answered: true
                ),
                number: 3
              )
            ]
          ),
          OpenStruct.new(
            portal_name: "Group C",
            proposal_details: [
              OpenStruct.new(
                question: "Question 4",
                responses: [OpenStruct.new(value: "Answer 4")],
                metadata: OpenStruct.new(portal_name: "Group C"),
                number: 4
              )
            ]
          )
        ]
      )
    end
  end
end
