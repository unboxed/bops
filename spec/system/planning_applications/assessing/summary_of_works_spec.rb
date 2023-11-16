# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Summary of works" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application, :in_assessment, local_authority: default_local_authority)
  end

  before do
    sign_in assessor
    visit planning_application_path(planning_application)
  end

  context "when planning application is in assessment" do
    it "I can view the information on the summary of works page" do
      click_link "Check and assess"

      within("#assessment-information-tasks") do
        expect(page).to have_content("Not started")
        click_link "Summary of works"
      end

      within(".govuk-breadcrumbs__list") do
        expect(page).to have_content("Summary")
      end

      expect(page).to have_current_path(
        "/planning_applications/#{planning_application.id}/assessment/assessment_details/new?category=summary_of_work"
      )

      expect(page).to have_content(planning_application.reference)
      expect(page).to have_content(planning_application.full_address)
      expect(page).to have_content("You can include:")

      within(".govuk-warning-text") do
        expect(page).to have_content("This information will be made publicly available.")
      end
    end

    it "there is a validation error when submitting an empty text field" do
      click_link "Check and assess"
      click_link "Summary of works"

      click_button "Save and mark as complete"
      within(".govuk-error-summary") do
        expect(page).to have_content "Entry can't be blank"
      end

      click_button "Save and come back later"
      within(".govuk-error-summary") do
        expect(page).to have_content "Entry can't be blank"
      end
    end

    it "I can save and come back later when adding or editing a summary of work" do
      expect(list_item("Check and assess")).to have_content("Not started")
      click_link "Check and assess"
      click_link "Summary of works"

      fill_in "assessment_detail[entry]", with: "A draft entry for the summary of works"
      click_button "Save and come back later"

      expect(page).to have_content("Summary of works was successfully created.")

      within("#assessment-information-tasks") do
        expect(page).to have_content("In progress")
      end

      click_link "Summary of works"
      expect(page).to have_content("Edit summary of works")
      expect(page).to have_content("A draft entry for the summary of works")

      within(".govuk-breadcrumbs__list") do
        expect(page).to have_content("Edit summary of works")
      end

      click_button "Save and come back later"
      expect(page).to have_content("Summary of works was successfully updated.")

      within("#assessment-information-tasks") do
        expect(page).to have_content("In progress")
      end

      click_link("Application")

      expect(list_item("Check and assess")).to have_content("In progress")
    end

    it "I can save and mark as complete when adding a summary of work" do
      click_link "Check and assess"
      click_link "Summary of works"

      fill_in "assessment_detail[entry]", with: "A complete entry for the summary of works"
      click_button "Save and mark as complete"

      expect(page).to have_content("Summary of works was successfully created.")

      within("#assessment-information-tasks") do
        expect(page).to have_content("Completed")
      end

      click_link "Summary of works"
      expect(page).to have_content("Summary of works")
      expect(page).to have_content("A complete entry for the summary of works")

      expect(page).to have_link(
        "Edit summary of work",
        href: edit_planning_application_assessment_assessment_detail_path(planning_application, AssessmentDetail.summary_of_work.last, category: :summary_of_work)
      )
    end
  end

  context "when planning application has not been validated yet" do
    let!(:planning_application) do
      create(:planning_application, :not_started, local_authority: default_local_authority)
    end

    it "does not allow me to visit the page" do
      expect(page).not_to have_link("Summary of works")

      visit new_planning_application_assessment_assessment_detail_path(planning_application)

      expect(page).to have_content("forbidden")
    end
  end
end
