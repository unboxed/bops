# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReviewPolicyClassLinkComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:review_policy_class_link_component) do
    described_class.new(policy_class: policy_class)
  end

  it "displays edit link" do
    policy_class = create(:policy_class, section: "D", review_status: "not_checked_yet")
    render_inline(described_class.new(policy_class: policy_class))

    expect(page).to have_link("Review assessment of Part 1, Class D",
                              href: edit_planning_application_review_policy_class_path(policy_class.planning_application, policy_class))
  end

  it "displays show link" do
    policy_class = create(:policy_class, section: "D", review_status: "complete")
    render_inline(described_class.new(policy_class: policy_class))

    expect(page).to have_link("Review assessment of Part 1, Class D",
                              href: planning_application_review_policy_class_path(policy_class.planning_application, policy_class))
  end
end
