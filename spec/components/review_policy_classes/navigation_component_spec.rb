# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReviewPolicyClasses::NavigationComponent, type: :component do
  let(:planning_application) { create(:planning_application) }

  it "hides when the only policy class" do
    policy_class = create(:policy_class, section: "C", planning_application:)

    render_inline(described_class.new(policy_class:))

    expect(page).not_to have_text "View previous class"
    expect(page).not_to have_text "View next class"
  end

  it "displays previous with lower sort policy_class" do
    prv = create(:policy_class, section: "B", planning_application:)
    policy_class = create(:policy_class, section: "C", planning_application:)

    render_inline(described_class.new(policy_class:))

    expect(page).to have_link "View previous class",
                              href: edit_planning_application_review_policy_class_path(planning_application, prv)
    expect(page).not_to have_text "View next class"
  end

  it "displays next with higher sort policy_class" do
    policy_class = create(:policy_class, section: "C", planning_application:)
    nxt = create(:policy_class, section: "D", planning_application:)

    render_inline(described_class.new(policy_class:))

    expect(page).not_to have_text "View previous class"
    expect(page).to have_link "View next class",
                              href: edit_planning_application_review_policy_class_path(planning_application, nxt)
  end

  it "displays both links with higher and lower sort policy_class" do
    prv = create(:policy_class, section: "B", planning_application:)
    policy_class = create(:policy_class, section: "C", planning_application:)
    nxt = create(:policy_class, section: "D", planning_application:)

    render_inline(described_class.new(policy_class:))

    expect(page).to have_link "View previous class",
                              href: edit_planning_application_review_policy_class_path(planning_application, prv)
    expect(page).to have_link "View next class",
                              href: edit_planning_application_review_policy_class_path(planning_application, nxt)
  end
end
