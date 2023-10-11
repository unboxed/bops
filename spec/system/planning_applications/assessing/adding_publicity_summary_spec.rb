# frozen_string_literal: true

require "rails_helper"

RSpec.describe "neighbour responses" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  let!(:application_type) { create(:application_type, name: :prior_approval) }
  let!(:planning_application) do
    create(:planning_application, :in_assessment, :from_planx_immunity, application_type:,
                                                                        local_authority: default_local_authority)
  end

  before do
    sign_in assessor
    visit planning_application_path(planning_application)
  end

  context "when planning application is in assessment" do
    let!(:consultation) { create(:consultation, end_date: Time.zone.now, planning_application:) }
    let!(:neighbour1) { create(:neighbour, address: "1 Test Lane", consultation:) }
    let!(:neighbour2) { create(:neighbour, address: "2 Test Lane", consultation:) }
    let!(:neighbour3) { create(:neighbour, address: "3 Test Lane", consultation:) }
    let!(:objection_response) { create(:neighbour_response, neighbour: neighbour1, summary_tag: "objection") }
    let!(:supportive_response1) { create(:neighbour_response, neighbour: neighbour3, summary_tag: "supportive") }
    let!(:supportive_response2) { create(:neighbour_response, neighbour: neighbour3, summary_tag: "supportive") }
    let!(:neutral_response) { create(:neighbour_response, neighbour: neighbour2, summary_tag: "neutral") }

    it "I can view the information on the neighbour responses page" do
      click_link "Check and assess"

      within("#assessment-information-tasks") do
        expect(page).to have_content("Summary of neighbour responses")
      end
      within("#summary-of-neighbour-responses") do
        expect(page).to have_content("Not started")
        click_link "Summary of neighbour responses"
      end

      expect(page).to have_link(
        "View neighbour responses",
        href: new_planning_application_consultation_neighbour_response_path(planning_application)
      )

      within(".govuk-notification-banner") do
        expect(page).to have_content("View neighbour responses")
        expect(page).to have_content("There is 1 neutral, 1 objection, 2 supportive.")
      end

      expect(page).to have_current_path(
        new_planning_application_assessment_detail_path(planning_application, category: "publicity_summary")
      )

      within(".govuk-breadcrumbs__list") do
        expect(page).to have_content("Summary of neighbour responses")
      end

      expect(page).to have_content("Add summary of neighbour responses")
      expect(page).to have_content(planning_application.reference)
      expect(page).to have_content(planning_application.full_address)

      expect(page).to have_content("This information will be made publicly available.")
    end

    it "I can save and come back later when adding or editing neighbour responses" do
      expect(list_item("Check and assess")).to have_content("Not started")

      click_link "Check and assess"
      click_link "Summary of neighbour responses"

      fill_in "assessment_detail[entry]", with: "A draft entry for the neighbour responses"
      click_button "Save and come back later"

      expect(page).to have_content("neighbour responses was successfully created.")

      within("#summary-of-neighbour-responses") do
        expect(page).to have_content("In progress")
      end

      click_link "Summary of neighbour responses"
      expect(page).to have_content("Edit summary of neighbour responses")
      expect(page).to have_content("A draft entry for the neighbour responses")

      within(".govuk-breadcrumbs__list") do
        expect(page).to have_content("Edit summary of neighbour responses")
      end

      within(".govuk-notification-banner") do
        expect(page).to have_content("View neighbour responses")
        expect(page).to have_content("There is 1 neutral, 1 objection, 2 supportive.")
      end

      click_button "Save and come back later"
      expect(page).to have_content("neighbour responses was successfully updated.")

      within("#summary-of-neighbour-responses") do
        expect(page).to have_content("In progress")
      end

      click_link("Application")

      expect(list_item("Check and assess")).to have_content("In progress")
    end

    it "I can save and mark as complete when adding neighbour responses" do
      click_link "Check and assess"
      click_link "Summary of neighbour responses"

      fill_in "assessment_detail[entry]", with: "A complete entry for the neighbour responses"
      click_button "Save and mark as complete"

      expect(page).to have_content("neighbour responses was successfully created.")

      within("#summary-of-neighbour-responses") do
        expect(page).to have_content("Completed")
      end

      click_link "Summary of neighbour responses"
      expect(page).to have_content("Summary of neighbour responses")
      expect(page).to have_content("A complete entry for the neighbour responses")

      expect(page).to have_link(
        "Edit summary of neighbour responses",
        href: edit_planning_application_assessment_detail_path(planning_application,
                                                               AssessmentDetail.publicity_summary.last)
      )
    end
  end

  context "when planning application has not been validated yet" do
    let!(:planning_application) do
      create(:planning_application, :not_started, local_authority: default_local_authority)
    end

    it "does not allow me to visit the page" do
      expect(page).not_to have_link("neighbour responses")

      visit new_planning_application_assessment_detail_path(planning_application)

      expect(page).to have_content("forbidden")
    end
  end

  context "when it's an LDC application" do
    let!(:application_type) { create(:application_type, name: :lawfulness_certificate) }
    let!(:planning_application) do
      create(:planning_application, :in_assessment, application_type:, local_authority: default_local_authority)
    end

    it "does not show neighbour responses as an option" do
      click_link "Check and assess"

      within("#assessment-information-tasks") do
        expect(page).not_to have_content("Summary of neighbour responses")
      end
    end
  end
end
