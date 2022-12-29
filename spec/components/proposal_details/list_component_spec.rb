# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProposalDetails::ListComponent, type: :component do
  let(:proposal_details) do
    [
      {
        question: "Test question 1",
        responses: [{ value: "Test response 1" }],
        metadata: { auto_answered: true, portal_name: "group_a" }
      },
      {
        question: "Test question 2",
        responses: [{ value: "Test response 2" }],
        metadata: { auto_answered: true, portal_name: "group_b" }
      },
      {
        question: "Test question 3",
        responses: [{ value: "Test response 3" }],
        metadata: { auto_answered: true, portal_name: "group_a" }
      }
    ].to_json
  end

  let(:planning_application) do
    build(:planning_application, proposal_details: proposal_details)
  end

  let(:component) do
    described_class.new(
      proposal_details: planning_application.proposal_details
    )
  end

  before { render_inline(component) }

  it "renders 'Hide auto answered' check box" do
    expect(page).to have_field(
      "View ONLY applicant answers, hide 'Auto-answered by RIPA'"
    )
  end

  it "renders a link for first group" do
    expect(page).to have_link("Group a", href: "#groupa")
  end

  it "renders a link for second group" do
    expect(page).to have_link("Group b", href: "#groupb")
  end

  it "renders first group with correct numbered questions" do
    group_a = page.find("h4", text: "Group a").find(:xpath, "../..")
    expect(group_a).to have_content("1. \n  \n    Test question 1")
    expect(group_a).to have_content("2. \n  \n    Test question 3")
  end

  it "renders second group with correct numbered questions" do
    group_b = page.find("h4", text: "Group b").find(:xpath, "../..")
    expect(group_b).to have_content("3. \n  \n    Test question 2")
  end
end
