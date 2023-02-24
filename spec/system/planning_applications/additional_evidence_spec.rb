# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Additional evidence" do
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
    it "I can view the information on the additional evidence page" do
      click_link "Check and assess"

      within("#assessment-information-tasks") do
        expect(page).to have_content("Not started")
        click_link "Summary of additional evidence"
      end

      expect(page).to have_current_path(
        new_planning_application_assessment_detail_path(planning_application, category: "additional_evidence")
      )

      within(".govuk-breadcrumbs__list") do
        expect(page).to have_content("Summary of additional evidence")
      end

      expect(page).to have_content("Add detail of additional evidence")
      expect(page).to have_content(planning_application.reference)
      expect(page).to have_content(planning_application.full_address)

      expect(page).to have_content("What is the impact of any additional evidence on the application?")
      expect(page).to have_content("This information will NOT be made public.")
      expect(page).to have_content(
        "This task is optional. Provide any additional information that will impact the assessment of this application."
      )
    end

    it "I can save and come back later when adding or editing additional evidence" do
      expect(list_item("Check and assess")).to have_content("Not started")

      click_link "Check and assess"
      click_link "Summary of additional evidence"

      fill_in "assessment_detail[entry]", with: "A draft entry for the additional evidence"
      click_button "Save and come back later"

      expect(page).to have_content("Additional evidence was successfully created.")

      within("#assessment-information-tasks") do
        expect(page).to have_content("In progress")
      end

      click_link "Summary of additional evidence"
      expect(page).to have_content("Edit additional evidence")
      expect(page).to have_content("A draft entry for the additional evidence")

      within(".govuk-breadcrumbs__list") do
        expect(page).to have_content("Edit additional evidence")
      end

      click_button "Save and come back later"
      expect(page).to have_content("Additional evidence was successfully updated.")

      within("#assessment-information-tasks") do
        expect(page).to have_content("In progress")
      end

      click_link("Application")

      expect(list_item("Check and assess")).to have_content("In progress")
    end

    it "I can save and mark as complete when adding additional evidence" do
      click_link "Check and assess"
      click_link "Summary of additional evidence"

      fill_in "assessment_detail[entry]", with: "A complete entry for the additional evidence"
      click_button "Save and mark as complete"

      expect(page).to have_content("Additional evidence was successfully created.")

      within("#assessment-information-tasks") do
        expect(page).to have_content("Completed")
      end

      click_link "Summary of additional evidence"
      expect(page).to have_content("Summary of additional evidence")
      expect(page).to have_content("A complete entry for the additional evidence")

      expect(page).to have_link(
        "Edit additional evidence",
        href: edit_planning_application_assessment_detail_path(planning_application, AssessmentDetail.additional_evidence.last)
      )
    end
  end

  context "when planning application has not been validated yet" do
    let!(:planning_application) do
      create(:planning_application, :not_started, local_authority: default_local_authority)
    end

    it "does not allow me to visit the page" do
      expect(page).not_to have_link("Additional evidence")

      visit new_planning_application_assessment_detail_path(planning_application)

      expect(page).to have_content("forbidden")
    end
  end
end
