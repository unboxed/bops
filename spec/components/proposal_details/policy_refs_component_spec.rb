# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProposalDetails::PolicyRefsComponent, type: :component do
  let(:policy_refs) do
    [{ "url" => "www.example.com" }, { "text" => "Test ref" }]
  end

  let(:component) { described_class.new(policy_refs:) }

  before { render_inline(component) }

  it "renders link for polify ref with url" do
    expect(page).to have_link(
      "www.example.com",
      href: "www.example.com",
      visible: :hidden
    )
  end

  it "renders text for policy ref without url" do
    expect(page).to have_content("Test ref")
  end
end
