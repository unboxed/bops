# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Planning Application index page", type: :system do
  let!(:second_assessor) { create(:user, :assessor) }
  let!(:planning_application_1) { create(:planning_application) }
  let!(:planning_application_2) { create(:planning_application) }
  let!(:planning_application_3) { create(:planning_application, user_id: second_assessor.id) }
  let!(:planning_application_started) { create(:planning_application, :awaiting_determination) }
  let!(:planning_application_completed) { create(:planning_application, :determined) }

  context "as an assessor" do
    before do
      sign_in users(:assessor)
      visit planning_applications_path
    end

    scenario "Planning Application status bar is present" do
      within(:planning_applications_status_tab) do
        expect(page).to have_link "In assessment"
        expect(page).to have_link "Awaiting manager's determination"
        expect(page).to have_link "Determined"
      end
    end

    scenario "Only Planning Applications that are in_assessment are present in this tab" do
      within("#in_assessment") do
        expect(page).to have_text("In assessment")
        expect(page).to have_link(planning_application_1.reference)
        expect(page).to have_link(planning_application_2.reference)
        expect(page).not_to have_link(planning_application_started.reference)
        expect(page).not_to have_link(planning_application_completed.reference)
      end
    end

    scenario "Only Planning Applications that are awaiting_determination are present in this tab" do
      click_link "Awaiting manager's determination"

      within("#awaiting_determination") do
        expect(page).to have_text("Awaiting manager's determination")
        expect(page).to have_link(planning_application_started.reference)
        expect(page).not_to have_link(planning_application_1.reference)
        expect(page).not_to have_link(planning_application_2.reference)
        expect(page).not_to have_link(planning_application_completed.reference)
      end
    end

    scenario "Only Planning Applications that are determined are present in this tab" do
      click_link "Determined"

      within("#determined") do
        expect(page).to have_text("Determined")
        expect(page).to have_link(planning_application_completed.reference)
        expect(page).not_to have_link(planning_application_1.reference)
        expect(page).not_to have_link(planning_application_2.reference)
        expect(page).not_to have_link(planning_application_started.reference)
      end
    end

    scenario "Breadcrumbs are not displayed" do
      within(find(".govuk-breadcrumbs__list", match: :first)) do
        expect(page).to have_no_text "Home"
        expect(page).to have_no_text "Application"
      end
    end

    scenario "User can log out from index page" do
      click_button "Log out"

      expect(page).to have_current_path(/sign_in/)
      expect(page).to have_content("You need to sign in or sign up before continuing.")
    end

    scenario "On login, assessor gets redirected to a view with its own and unassigned Planning Applications" do
      within("#in_assessment") do
        expect(page).to have_text("In assessment")
        expect(page).to have_link(planning_application_1.reference)
        expect(page).to have_link(planning_application_2.reference)
        expect(page).not_to have_link(planning_application_3.reference)
      end
    end

    scenario "An assessor can toggle the view to access all applications, including those assigned to others" do
      click_on "View all applications"

      within("#in_assessment") do
        expect(page).to have_text("In assessment")
        expect(page).to have_link(planning_application_1.reference)
        expect(page).to have_link(planning_application_2.reference)
        expect(page).to have_link(planning_application_3.reference)
      end
    end
  end

  context "as an reviewer" do
    before do
      sign_in users(:reviewer)
      visit planning_applications_path
    end

    scenario "Planning Application status bar is present" do
      within(:planning_applications_status_tab) do
        expect(page).to have_link "Awaiting manager's determination"
        expect(page).to have_link "Determined"
        expect(page).not_to have_link "In assessment"
      end
    end

    scenario "Only Planning Applications that are awaiting_determination are present in this tab" do
      click_link "Awaiting manager's determination"

      within("#awaiting_determination") do
        expect(page).to have_text("Awaiting manager's determination")
        expect(page).to have_link(planning_application_started.reference)
        expect(page).not_to have_link(planning_application_1.reference)
        expect(page).not_to have_link(planning_application_2.reference)
        expect(page).not_to have_link(planning_application_completed.reference)
      end
    end

    scenario "Only Planning Applications that are determined are present in this tab" do
      click_link "Determined"

      within("#determined") do
        expect(page).to have_text("Determined")
        expect(page).to have_link(planning_application_completed.reference)
        expect(page).not_to have_link(planning_application_1.reference)
        expect(page).not_to have_link(planning_application_2.reference)
        expect(page).not_to have_link(planning_application_started.reference)
      end
    end

    scenario "Breadcrumbs are not displayed" do
      within(find(".govuk-breadcrumbs__list", match: :first)) do
        expect(page).to have_no_text "Home"
        expect(page).to have_no_text "Application"
      end
    end

    scenario "User can log out from index page" do
      click_button "Log out"

      expect(page).to have_current_path(/sign_in/)
      expect(page).to have_content("You need to sign in or sign up before continuing.")
    end
  end
end
