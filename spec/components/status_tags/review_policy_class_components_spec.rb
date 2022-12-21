# frozen_string_literal: true

require "rails_helper"

RSpec.describe StatusTags::ReviewPolicyClassComponent, type: :component do
  it "displays start status" do
    review_policy_class = create(:review_policy_class, status: :not_checked_yet)

    render_inline(described_class.new(review_policy_class: review_policy_class))

    expect(page).to have_css ".govuk-tag--grey", text: "Not checked yet"
  end

  it "displays complete status" do
    review_policy_class = create(:review_policy_class, status: :complete)

    render_inline(described_class.new(review_policy_class: review_policy_class))

    expect(page).to have_css(".govuk-tag", text: "Completed")
  end
end
