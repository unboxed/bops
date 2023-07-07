# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProposalDetails::GroupComponent, type: :component do
  let(:proposal_detail_attributes) do
    {
      question: "Test question 1",
      responses: [{ value: "Test response 1" }],
      metadata: { section_name: "group_x" }
    }.deep_stringify_keys
  end

  let(:group) do
    Struct.new(:section_name, :proposal_details).new(
      "group_x",
      [ProposalDetail.new(proposal_detail_attributes, 1)]
    )
  end

  let(:component) { described_class.new(group:) }

  before { render_inline(component) }

  it "renders header" do
    expect(page).to have_content("Group x")
  end

  it "renders proposal details" do
    expect(page).to have_content("Test question 1")
  end
end
