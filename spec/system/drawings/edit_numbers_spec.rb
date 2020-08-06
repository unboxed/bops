# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Edit drawing numbers page", type: :system do
  fixtures :sites

  let!(:site) { sites(:elm_grove) }

  let!(:planning_application) do
    create :planning_application,
           :lawfulness_certificate,
           site: site
  end

  let(:drawing_tags) {
    ["front elevation - proposed", "floor plan - proposed"]
  }

  let!(:drawing) do
    create :drawing, :with_plan,
           planning_application: planning_application,
           tags: drawing_tags
  end

  context "as a user who is not logged in" do
    scenario "User cannot see edit_numbers page" do
      visit edit_numbers_planning_application_drawings_path(planning_application)
      expect(page).to have_current_path(/sign_in/)
      expect(page).to have_content("You need to sign in or sign up before continuing.")
    end
  end

  context "as an assessor" do
    before do
      sign_in users(:assessor)
      visit planning_application_path(planning_application)
      click_link "Attach drawing numbers"
    end
  #
    scenario "Assessor can see content for the right application" do
      expect(page).to have_text(planning_application.reference)
      expect(page).to have_text(planning_application.site.full_address)
      expect(page).to have_text("Attach drawing numbers")
      expect(page).to have_text("These will be published in the decision notice.")
    end

    scenario "Assessor can see information about the drawing" do
      expect(page).to have_text("front elevation - proposed")
      expect(page).to have_text("floor plan - proposed")
      expect(page).to have_text("proposed-floorplan.png")
    end

    scenario "Assessor is able to add drawing numbers and save them" do
      fill_in "numbers", with: "12343, 324321432432"
      click_button "Save"
      expect(page).to have_text("Assess the proposal")
    end
  end
end
