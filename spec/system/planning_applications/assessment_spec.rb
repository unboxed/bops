# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning Application Assessment" do
  let!(:planning_application) do
    create :planning_application,
           application_type: :lawfulness_certificate,
           reference: "19/AP/1880"
  end

  context "as an assessor" do
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
end
