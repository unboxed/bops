# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Recommended application type assessment task" do
  let!(:local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: local_authority) }

  before do
    sign_in assessor
  end

  context "when application is not pre advice" do
    let!(:planning_application) do
      create(:planning_application, :awaiting_determination, local_authority: local_authority)
    end

    it "does not have a section to recommended application type" do
      visit "/planning_applications/#{planning_application.reference}/assessment/tasks"

      expect(page).not_to have_css("#choose-application-type")
      expect(page).not_to have_content("Choose application type")
    end
  end

  context "when application is not started" do
    let!(:application_type) { create(:application_type, :prior_approval, local_authority: local_authority) }

    let!(:planning_application) do
      create(:planning_application, :awaiting_determination, :pre_application, local_authority: local_authority)
    end

    before do
      visit "/planning_applications/#{planning_application.reference}/assessment/tasks"
    end

    it "I can see that reporting type is not started" do
      expect(page).to have_link(
        "Choose application type",
        href: "/planning_applications/#{planning_application.reference}/assessment/recommended_application_type/edit"
      )
      click_link "Choose application type"

      expect(page).to have_content("Choose application type")

      click_link "Back"

      within("#choose-application-type") do
        expect(page).to have_selector(".govuk-tag", text: "Not started")
      end
    end

    it "I can choose the recommended application type" do
      click_link "Choose application type"

      expect(page).to have_content("Choose application type")

      select "Prior Approval - Larger extension to a house", from: "What application type would the applicant need to apply for next?"

      click_button "Save and mark as complete"

      within(".govuk-notification-banner--notice") do
        expect(page).to have_content("Recommended application type was successfully chosen.")
      end

      within("#choose-application-type") do
        expect(page).to have_selector(".govuk-tag", text: "Completed")
      end

      expect(page).to have_link(
        "Choose application type",
        href: "/planning_applications/#{planning_application.reference}/assessment/recommended_application_type"
      )

      click_link "Choose application type"

      expect(page).to have_content "Prior Approval - Larger extension to a house"
    end

    it "shows errors when a recommended application type is not selected" do
      click_link "Choose application type"

      click_button "Save and mark as complete"

      expect(page).to have_content "Recommended application type can't be blank"
    end
  end
end
