# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Planning Application index page", type: :system do
  let!(:planning_application_1) { create(:planning_application) }
  let!(:planning_application_2) { create(:planning_application) }
  let!(:planning_application_started) { create(:planning_application, :started) }
  let!(:planning_application_completed) { create(:planning_application, :completed) }

  context "as an assessor" do
    before do
      sign_in users(:assessor)
      visit "/planning_applications"
    end

    scenario "Planning Application status bar is present" do
      within(:planning_applications_status_tab) do
        expect(page).to have_link "Pending"
        expect(page).to have_link "Started"
        expect(page).to have_link "Completed"
      end
    end

    scenario "Only Pending Planning Applications are present at pending tab" do
      within("#pending") do
        expect(page).to have_link(planning_application_1.reference)
        expect(page).to have_link(planning_application_2.reference)
        expect(page).not_to have_link(planning_application_started.reference)
        expect(page).not_to have_link(planning_application_completed.reference)
      end
    end

    scenario "Only Started Planning Applications are present at started tab" do
      click_link "Started"

      within("#started") do
        expect(page).to have_link(planning_application_started.reference)
        expect(page).not_to have_link(planning_application_1.reference)
        expect(page).not_to have_link(planning_application_2.reference)
        expect(page).not_to have_link(planning_application_completed.reference)
      end
    end

    scenario "Only Completed Planning Applications are present at completed tab" do
      click_link "Completed"

      within("#completed") do
        expect(page).to have_link(planning_application_completed.reference)
        expect(page).not_to have_link(planning_application_1.reference)
        expect(page).not_to have_link(planning_application_2.reference)
        expect(page).not_to have_link(planning_application_started.reference)
      end
    end
  end
end
