# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReviewTasks::AfterSignOffComponent, type: :component do
  let(:assessor) { create(:user, :assessor, name: "John") }

  # this state only happens with incorrectly setup tests
  # otherwise recommendation has been set before you ever
  # get to sign off
  it "renders nothing when no recommendation" do
    pa = create(:planning_application)

    render_inline(described_class.new(planning_application: pa))

    expect(page).not_to have_selector("body")
  end

  it "renders nothing when not submitted" do
    rec = create(:recommendation,
                 :with_planning_application,
                 submitted: false,
                 challenged: false)

    render_inline(described_class.new(planning_application: rec.planning_application))

    expect(page).not_to have_selector("body")
  end

  # 3 state boolean
  %i[true nil].each do |challenged|
    it "renders assessment name when submitted and challenged" do
      rec = create(:recommendation,
                   :with_planning_application,
                   status: :review_complete,
                   reviewer_comment: "reviewer comment",
                   submitted: true,
                   challenged: challenged,
                   assessor: assessor)

      render_inline(described_class.new(planning_application: rec.planning_application))

      expect(page).to have_text "Application is now in assessment and assigned to John"
    end
  end
end
