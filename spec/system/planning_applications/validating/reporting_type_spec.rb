# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reporting type validation task" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application, :invalidated, local_authority: default_local_authority)
  end

  before do
    sign_in assessor
    visit "/planning_applications/#{planning_application.id}/validation/tasks"
  end

  context "when application is not started" do
    it "I can see that reporting type is not started" do
      expect(page).to have_link(
        "Select development type for reporting",
        href: "/planning_applications/#{planning_application.id}/validation/reporting_type/edit"
      )
      click_link "Select development type for reporting"

      expect(page).to have_content("Select development type for reporting")

      expect(page).to have_content("Select development type")

      click_link "Back"

      within("#development-type-for-reporting-task") do
        expect(page).to have_selector(".govuk-tag", text: "Not started")
      end
    end

    it "I can select the development type for reporting" do
      click_link "Select development type for reporting"

      expect(page).to have_content("Select development type for reporting")

      choose "Q26 - Certificate of Lawful Development"

      expect(page).to have_content("Guidance")
      expect(page).to have_content("Includes both Existing & Proposed applications")

      click_button "Save and mark as complete"

      within(".govuk-notification-banner--notice") do
        expect(page).to have_content("Planning application's development type for reporting was successfully selected")
      end

      within("#development-type-for-reporting-task") do
        expect(page).to have_selector(".govuk-tag", text: "Completed")
      end

      expect(page).to have_link(
        "Select development type for reporting",
        href: "/planning_applications/#{planning_application.id}/validation/reporting_type/edit"
      )
    end

    it "shows errors when a development type for reporting is not selected" do
      click_link "Select development type for reporting"

      click_button "Save and mark as complete"

      expect(page).to have_content "Please select a development type for reporting"
    end
  end
end
