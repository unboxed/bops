# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProposalDetails::SummaryComponent, type: :component do
  let(:proposal_detail_attributes) do
    {
      question: "Test question 1",
      responses: [{ value: "Test response 1" }, { value: "Test response 2" }],
      metadata: {
        section_name: "group_x",
        notes: "Test note",
        auto_answered: true,
        policy_refs: [{ url: "www.example.com" }, { text: "Test ref" }]
      }
    }.deep_stringify_keys
  end

  let(:proposal_detail) { ProposalDetail.new(proposal_detail_attributes, 1) }
  let(:component) { described_class.new(proposal_detail:) }

  before { render_inline(component) }

  it "renders question" do
    expect(page).to have_content("Test question 1")
  end

  it "renders responses" do
    expect(page).to have_content("Test response 1, Test response 2")
  end

  it "renders 'Auto-answered'" do
    expect(page).to have_content("Auto-answered by PlanX")
  end

  it "renders note" do
    expect(page).to have_content("Test note")
  end

  it "renders link for polify ref with url" do
    expect(page).to have_link("www.example.com", href: "www.example.com")
  end

  it "renders text for policy ref without url" do
    expect(page).to have_content("Test ref")
  end
end
