# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Drawings index page", type: :system do
  fixtures :sites

  let!(:site) { sites(:elm_grove) }

  let!(:planning_application) do
    create :planning_application,
           :lawfulness_certificate,
           site: site,
           reference: "19/AP/1880"
  end

  let!(:drawing) do
    create :drawing, :with_plan,
           planning_application: planning_application
  end

  context "as a user who is not logged in" do
    scenario "User cannot see archive page" do
      visit planning_application_drawings_path(planning_application)
      expect(page).to have_current_path(/sign_in/)
      expect(page).to have_content("You need to sign in or sign up before continuing.")
    end
  end

  context "as an assessor" do
    before do
      sign_in users(:assessor)
      visit planning_application_path(planning_application)
      click_button "Proposal documents"
      click_link "Manage documents"
    end

    scenario "Assessor can see Archive links when application is in determination" do
      expect(page).to have_css(".thumbnail-left")
    end

    scenario "Archive table is initially empty" do
      expect(page).to have_text "No documents archived"
      expect(page).not_to have_css(".archive-data")
    end
  end

  context "archiving journey" do
    before do
      sign_in users(:assessor)
      visit planning_application_path(planning_application)
      click_button "Proposal documents"
      click_link "Manage documents"
      click_link "Archive document"
    end

    scenario "Archive page contains radio buttons and image" do
      expect(page).to have_text "Missing scale bar/north arrow"
      expect(page).to have_css(".govuk-radios__item")
    end

    scenario "Archive page contains site info" do
      expect(page).to have_text "Elm Grove"
    end

    scenario "Archive page contains application reference" do
      expect(page).to have_text "19/AP/1880"
    end

    scenario "Breadcrumbs are correct on archive page" do
      within(find(".govuk-breadcrumbs__list", match: :first)) do
        expect(page).to have_link "Application"
        expect(page).to have_link "Home"
        expect(page).to have_text "Archive document"
        expect(page).to have_no_link "Archive document"
      end
    end

    scenario "User can log out from archive page" do
      click_button "Log out"

      expect(page).to have_current_path(/sign_in/)
      expect(page).to have_content("You need to sign in or sign up before continuing.")
    end

    scenario "Assessor sees flash warning if no radio button selected" do
      click_button "Save"
      expect(page).to have_text("Please select valid reason for archiving")
    end

    scenario "Assessor can proceed to confirmation page" do
      page.find(id: "revise-dimensions").click
      click_button "Save"
      expect(page).to have_current_path(/validate_step/)
    end

    scenario "Correct reason is shown on confirmation page" do
      page.find(id: "revise-dimensions").click
      click_button "Save"
      expect(page).to have_text("Revise dimensions")
    end

    scenario "Assessor is returned to archive page if radio button not selected" do
      page.find(id: "revise-dimensions").click
      click_button "Save"
      click_button "Archive document"

      expect(page).to have_text("Why do you want to archive this document?")
    end

    scenario "Assessor is returned to archive page if 'No' is selected" do
      page.find(id: "revise-dimensions").click
      click_button "Save"
      page.find(id: "archive-no").click
      click_button "Archive document"

      expect(page).to have_text("Why do you want to archive this document?")
    end

    scenario "Assessor can archive a document" do
      page.find(id: "revise-dimensions").click
      click_button "Save"

      page.find(id: "archive-yes").click
      click_button "Archive document"

      expect(page).to have_current_path(/drawings/)
    end

    scenario "Archived document appears in correct place on DMS page" do
      page.find(id: "revise-dimensions").click
      click_button "Save"
      page.find(id: "archive-yes").click
      click_button "Archive document"

      within(find(".archived-drawings")) do
        expect(page).to have_text("Revise dimensions")
        expect(page).to have_text("Side elevation")
      end
    end

    scenario "Archived document does not appear on overview page" do
      expect(page).not_to have_css(".thumbnail-left")
    end
  end
end
