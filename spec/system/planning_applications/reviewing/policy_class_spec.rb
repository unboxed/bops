# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning Application Reviewing Policy Class", type: :system do
  let(:default_local_authority) { create(:local_authority, :default) }
  let(:reviewer) { create :user, :reviewer, local_authority: default_local_authority }
  let!(:planning_application) do
    create(
      :planning_application,
      :awaiting_determination,
      local_authority: default_local_authority
    )
  end

  context "with a reviewer" do
    before do
      sign_in reviewer
    end

    it "can make the policy class reviewed" do
      create(:policy_class, section: "A", planning_application: planning_application)
      visit(planning_application_review_tasks_path(planning_application))

      expect(page).to have_selector("h1", text: "Review and sign-off")
      click_on "Review assessment of Part 1, Class A"

      choose "Accept"

      click_on "Save and mark as complete"

      expect(page).to have_text "Successfully updated policy class"

      expect(list_item("Review assessment of Part 1, Class A")).to have_content("Complete")

      # READ only page

      click_on "Review assessment of Part 1, Class A"

      click_on "Save and come back later"

      expect(page).to have_text "Successfully updated policy class"

      expect(list_item("Review assessment of Part 1, Class A")).to have_content("Not checked yet")
    end
  end
end
