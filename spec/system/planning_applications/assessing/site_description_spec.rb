# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Site description" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application, :in_assessment, local_authority: default_local_authority)
  end

  let(:reference) { planning_application.reference }
  let(:full_address) { planning_application.full_address }
  let(:assessment_detail) { planning_application.assessment_details.last.id }

  before do
    sign_in assessor
    visit "/planning_applications/#{reference}"
  end

  context "when planning application is in assessment" do
    before do
      click_link "Check and assess"
    end

    it "I can view the information on the site description page" do
      within("#assessment-information-tasks") do
        expect(page).to have_content("Not started")
        click_link "Site description"
      end

      expect(page).to have_current_path(
        "/planning_applications/#{reference}/assessment/assessment_details/new?category=site_description"
      )

      expect(page).to have_link(
        "View site on Google Maps",
        href: "https://google.co.uk/maps/place/#{CGI.escape(full_address)}"
      )

      expect(page).to have_content("Create a description of the site")
      expect(page).to have_content(reference)
      expect(page).to have_content(full_address)
      expect(page).to have_content("You can include:")

      within(".govuk-warning-text") do
        expect(page).to have_content("This information WILL be made publicly available.")
      end
    end

    it "there is a validation error when submitting an empty text field" do
      click_link "Site description"
      expect(page).to have_content("Create a description of the site")

      click_button "Save and mark as complete"
      within(".govuk-error-summary") do
        expect(page).to have_content("Enter Entry")
      end

      click_button "Save and come back later"
      within(".govuk-error-summary") do
        expect(page).to have_content("Enter Entry")
      end
    end

    it "I can save and come back later when adding or editing a site description" do
      click_link "Site description"
      expect(page).to have_content("Create a description of the site")

      fill_in "Description of the site", with: "A draft entry for the site description"
      click_button "Save and come back later"

      expect(page).to have_content("Site description was successfully created.")

      within("#assessment-information-tasks") do
        expect(page).to have_content("In progress")
      end

      click_link "Site description"
      expect(page).to have_content("Edit site description")
      expect(page).to have_content("A draft entry for the site description")

      click_button "Save and come back later"
      expect(page).to have_content("Site description was successfully updated.")

      within("#assessment-information-tasks") do
        expect(page).to have_content("In progress")
      end
    end

    it "I can save and mark as complete when adding a site description" do
      click_link "Site description"

      fill_in "Description of the site", with: "A complete entry for the site description"
      click_button "Save and mark as complete"

      expect(page).to have_content("Site description was successfully created.")

      within("#assessment-information-tasks") do
        expect(page).to have_content("Completed")
      end

      click_link "Site description"
      expect(page).to have_content("Site description")
      expect(page).to have_content("A complete entry for the site description")

      expect(page).to have_link(
        "Edit site description",
        href: "/planning_applications/#{reference}/assessment/assessment_details/#{assessment_detail}/edit?category=site_description"
      )
    end
  end

  context "when planning application has not been validated yet" do
    let!(:planning_application) do
      create(:planning_application, :not_started, local_authority: default_local_authority)
    end

    it "does not allow me to visit the page" do
      expect(page).not_to have_link("Site description")

      visit "/planning_applications/#{reference}/assessment/assessment_details/new"
      expect(page).to have_content("The planning application must be validated before assessment can begin")
    end
  end

  context "when planning application is a pre-application" do
    let!(:planning_application) do
      create(:planning_application, :pre_application, :in_assessment, local_authority: default_local_authority)
    end

    it "does not show the information will be made public warning" do
      click_link "Check and assess"
      click_link "Site and surroundings"

      expect(page).to have_current_path(
        "/preapps/#{reference}/check-and-assess/assessment-summaries/site-and-surroundings"
      )

      expect(page).to have_content("Description of the site")
      expect(page).not_to have_content("This information WILL be made publicly available.")
    end
  end
end
