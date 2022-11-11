# frozen_string_literal: true

require "rails_helper"

RSpec.describe StatusTags::ReviewPolicyClassComponent, type: :component do
  let(:summary_component) do
    described_class.new(policy_class: policy_class)
  end

  it "displays start status" do
    policy_class = create(:policy_class)
    render_inline(described_class.new(policy_class: policy_class))

    expect(page).to have_css ".govuk-tag--grey", text: "Not checked yet"
  end
end
