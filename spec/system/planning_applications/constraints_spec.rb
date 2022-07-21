# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Constraints", type: :system do
  let!(:api_user) { create :api_user, name: "ApiUser" }
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create :user, :assessor, local_authority: default_local_authority }

  let!(:planning_application) do
    create :planning_application, :invalidated, local_authority: default_local_authority, api_user: api_user
  end

  before do
    sign_in assessor
    visit planning_application_constraints_path(planning_application)
  end

  it "displays the planning application address and reference" do
    expect(page).to have_content(planning_application.full_address.upcase)
    expect(page).to have_content(planning_application.reference)
  end

  context "when application is not started or invalidated" do
    it "displays the constraints" do
      within(".govuk-heading-l") do
        expect(page).to have_text("Check the constraints")
      end

      within(".govuk-heading-m") do
        expect(page).to have_text("Constraints identified by ApiUser")
      end

      within("#constraints-review") do
        expect(page).to have_text("Review all the constraints and update as necessary")
      end

      within(".govuk-list") do
        expect(page).to have_text("Conservation Area")
        expect(page).to have_text("Listed Building")
      end

      expect(page).to have_link("Back", href: planning_application_validation_tasks_path(planning_application))

      click_button "Marked as checked"

      expect(page).to have_link(
        "Check constraints",
        href: planning_application_constraints_path(planning_application)
      )
      within(".govuk-tag--green") do
        expect(page).to have_content("Checked")
      end

      visit planning_application_audits_path(planning_application)

      expect(page).to have_text("Constraints Checked")
    end
  end
end
