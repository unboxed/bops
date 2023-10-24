# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProposalDetails::LinkComponent, type: :component do
  let(:proposal_detail_attributes) do
    {
      question: "Test question 1",
      responses: [{value: "Test response 1"}],
      metadata: {section_name:}
    }.deep_stringify_keys
  end

  let(:section_name) { "group_x" }

  let(:group) do
    Struct.new(:section_name, :proposal_details).new(
      section_name,
      [ProposalDetail.new(proposal_detail_attributes, 1)]
    )
  end

  let(:component) { described_class.new(group:) }

  before { render_inline(component) }

  it "renders link to portal name" do
    expect(page).to have_link("Group x", href: "#groupx")
  end

  context "when section_name is nil" do
    let(:section_name) { nil }

    it "renders link to 'Other'" do
      expect(page).to have_link("Other", href: "#other")
    end
  end
end
