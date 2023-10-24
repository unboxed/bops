# frozen_string_literal: true

require "rails_helper"

RSpec.describe Review::PolicyClass::LinkComponent, type: :component do
  include Rails.application.routes.url_helpers
  let(:policy_class) { create(:policy_class, section: "D") }

  it "displays edit link when review policy_class nil" do
    policy_class = create(:policy_class, part: 1, section: "D")

    render_inline(described_class.new(policy_class:))

    expect(page).to have_link("Review assessment of Part 1, Class D",
      href: edit_planning_application_review_policy_class_path(policy_class.planning_application, policy_class))
  end

  it "displays edit link when status not checked yet" do
    review_policy_class = create(:review_policy_class, status: :not_started, policy_class:)

    render_inline(described_class.new(policy_class: review_policy_class.policy_class))

    expect(page).to have_link("Review assessment of Part 1, Class D",
      href: edit_planning_application_review_policy_class_path(policy_class.planning_application, policy_class))
  end

  it "displays show link when status complete" do
    review_policy_class = create(:review_policy_class, status: :complete, policy_class:)

    render_inline(described_class.new(policy_class: review_policy_class.policy_class))

    expect(page).to have_link("Review assessment of Part 1, Class D",
      href: planning_application_review_policy_class_path(policy_class.planning_application, policy_class))
  end
end
