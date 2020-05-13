# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning Application Assessment" do
  context "as an assessor" do
    # Work on a totally new application
    let!(:planning_application) do
      create :planning_application,
             application_type: :lawfulness_certificate,
             reference: "19/AP/1880"
    end

    before do
      sign_in users(:assessor)
      visit root_path
    end

    scenario "Assessment completing and editing" do
      click_link "19/AP/1880"

      # Ensure we're starting from a fresh "checklist"
      expect(page).not_to have_css(".app-task-list__task-completed")

      click_link "Evaluate permitted development policy requirements"
      choose "Yes"
      click_button "Save"

      # Expect the 'completed' label to be present for the evaluation step
      within(:assessment_step, "Evaluate permitted development policy requirements") do
        expect(page).to have_completed_tag
      end

      click_link "Evaluate permitted development policy requirements"

      # Expect the saved state to be shown in the form
      within(find("form.policy_evaluation")) do
        expect(page.find_field("Yes")).to be_checked
      end

      choose "No"
      click_button "Save"

      # Expect the 'completed' label to still be present for the evaluation step
      within(:assessment_step, "Evaluate permitted development policy requirements") do
        expect(page).to have_completed_tag
      end

      # TODO: Continue this spec until the assessor decision has been made and check that policy evaluations can no longer be made
    end
  end

  context "as a reviewer" do
    # Look at an application that has had some assessment work done by the assessor
    let!(:planning_application) do
      create :planning_application, :with_policy_evaluation_requirements_unmet, reference: "19/AP/1880"
    end

    before do
      sign_in users(:reviewer)

      visit root_path
    end

    scenario "Assessment reviewing" do
      # Visit the planning application URL directly, as it's not possible to navigate to it from the UI currently
      visit planning_application_path(planning_application)

      expect(page).not_to have_link "Evaluate permitted development policy requirements"

      within(:assessment_step, "Evaluate permitted development policy requirements") do
        expect(page).to have_completed_tag
      end

      # TODO: Continue this spec to check that the reviewer cannot do other actions meant for an assessor
    end
  end

  context "as an admin" do
    let!(:planning_application) do
      create :planning_application, :with_policy_evaluation_requirements_unmet, reference: "19/AP/1880"
    end

    before do
      sign_in users(:admin)

      visit root_path
    end

    scenario "Assessment editing" do
      # TODO: Define admin actions on a planning application further and test them

      click_link "19/AP/1880"

      expect(page).to have_link "Evaluate permitted development policy requirements"

      within(:assessment_step, "Evaluate permitted development policy requirements") do
        expect(page).to have_completed_tag
      end
    end
  end
end
