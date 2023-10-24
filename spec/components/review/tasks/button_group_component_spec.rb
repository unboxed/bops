# frozen_string_literal: true

require "rails_helper"

RSpec.describe Review::Tasks::ButtonGroupComponent, type: :component do
  # this state only happens with incorrectly setup tests
  # otherwise recommendation has been set before you ever
  # get to sign off
  it "renders only back button with no recommendation" do
    pa = create(:planning_application)

    render_inline(described_class.new(planning_application: pa))

    expect(page).not_to have_link("Review and publish decision",
      href: publish_planning_application_path(pa))
    expect(page).to have_link("Back",
      href: planning_application_path(pa))
  end

  it "renders only back button when not publishing" do
    rec = create(:recommendation,
      :with_planning_application,
      status: :review_complete,
      reviewer_comment: "reviewer comment",
      submitted: true,
      challenged: nil)
    render_inline(described_class.new(planning_application: rec.planning_application))

    expect(page).not_to have_link("Review and publish decision",
      href: publish_planning_application_path(rec.planning_application))
    expect(page).to have_link("Back",
      href: planning_application_path(rec.planning_application))
  end

  it "renders back and publish button when publishing" do
    rec = create(:recommendation,
      :with_planning_application,
      status: :review_complete,
      reviewer_comment: "reviewer comment",
      submitted: true,
      challenged: false)

    render_inline(described_class.new(planning_application: rec.planning_application))

    expect(page).to have_link("Review and publish decision",
      href: publish_planning_application_path(rec.planning_application))
    expect(page).to have_link("Back",
      href: planning_application_path(rec.planning_application))
  end
end
