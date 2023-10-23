# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Add conditions" do
  let!(:api_user) { create(:api_user, name: "PlanX") }
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application, :planning_permission, :in_assessment, :with_condition_set, local_authority: default_local_authority, api_user:, decision: "granted")
  end

  before do
    sign_in assessor
    visit planning_application_path(planning_application)
    click_link "Check and assess"
  end

  context "when planning application is planning permission" do
    it "you can add conditions" do
      click_link "Add conditions"

      expect(page).to have_content("Add conditions")

      check "Time limit"
      within(:css, "#standard-conditions .condition:nth-of-type(1)") do
        fill_in "Condition", with: "New condition"
      end
      check "Materials to match"

      click_link "+ Add condition"
      within(:css, "#other-conditions .condition:nth-of-type(1)") do
        fill_in "Condition", with: "Custom condition 1"
        fill_in "Reason", with: "Custom reason 1"
      end

      click_link "+ Add condition"
      within(:css, "#other-conditions .condition:nth-of-type(2)") do
        fill_in "Condition", with: "Custom condition 2"
        fill_in "Reason", with: "Custom reason 2"
      end

      click_link "+ Add condition"
      within(:css, "#other-conditions .condition:nth-of-type(3)") do
        fill_in "Condition", with: "Custom condition 3"
        fill_in "Reason", with: "Custom reason 3"
        click_link "Remove condition"
      end

      click_button "Save and mark as complete"

      expect(page).to have_content "Conditions successfully updated"

      within("#add-conditions") do
        expect(page).to have_content "Completed"
        click_link "Add conditions"
      end

      expect(page).to have_content "Time limit"
      expect(page).to have_content "New condition"
      expect(page).to have_content "To comply with the provisions of Section 91 of the Town and Country Planning Act 1990 (as amended)."
      expect(page).to have_content "Materials to match"
      expect(page).to have_content "All new external work and finishes and work of making good shall match the original work in respect of the materials, colour, texture, profile and finished appearance, except where indicated otherwise on the drawings hereby approved or unless otherwise required by condition."
      expect(page).to have_content "To preserve the character and appearance of the local area."
      expect(page).to have_content "Custom condition 1"
      expect(page).to have_content "Custom reason 1"
      expect(page).to have_content "Custom condition 2"
      expect(page).to have_content "Custom reason 2"
      expect(page).not_to have_content "Custom condition 3"
    end

    it "you can edit conditions" do
      create(:condition, condition_set: planning_application.condition_set, standard: true)
      create(:condition, condition_set: planning_application.condition_set, standard: false, text: "Condition 1", reason: "Reason 1")

      visit planning_application_path(planning_application)
      click_link "Check and assess"

      click_link "Add conditions"

      expect(page).to have_content "Time limit"
      expect(page).to have_content "The development herby permitted shall be commenced within three years of the date of this permission."
      expect(page).to have_content "To comply with the provisions of Section 91 of the Town and Country Planning Act 1990 (as amended)."
      expect(page).to have_content "Condition 1"
      expect(page).to have_content "Reason 1"

      click_link "Edit conditions"

      check "In accordance with approved plans"

      click_link "+ Add condition"
      within(:css, "#other-conditions .condition:nth-of-type(2)") do
        fill_in "Condition", with: "Custom condition 1"
        fill_in "Reason", with: "Custom reason 1"
      end

      click_button "Save and mark as complete"

      click_link "Add conditions"

      expect(page).to have_content "Time limit"
      expect(page).to have_content "The development herby permitted shall be commenced within three years of the date of this permission."
      expect(page).to have_content "To comply with the provisions of Section 91 of the Town and Country Planning Act 1990 (as amended)."
      expect(page).to have_content "In accordance with approved plans"
      expect(page).to have_content "The development herby permitted must be undertaken in accordance with the approved plans and documents."
      expect(page).to have_content "For the avoidance of doubt and in the interests of proper planning."
      expect(page).to have_content "Condition 1"
      expect(page).to have_content "Reason 1"
      expect(page).to have_content "Custom condition 1"
      expect(page).to have_content "Custom reason 1"

      click_link "Edit conditions"

      uncheck "Time limit"

      within(:css, "#other-conditions .condition:nth-of-type(1)") do
        click_link "Remove condition"
      end

      click_button "Save and mark as complete"

      click_link "Add conditions"

      expect(page).to have_content "In accordance with approved plans"
      expect(page).to have_content "The development herby permitted must be undertaken in accordance with the approved plans and documents."
      expect(page).to have_content "For the avoidance of doubt and in the interests of proper planning."
      expect(page).to have_content "Custom condition 1"
      expect(page).to have_content "Custom reason 1"

      expect(page).not_to have_content "Time limit"
      expect(page).not_to have_content "The development herby permitted shall be commenced within three years of the date of this permission."
      expect(page).not_to have_content "To comply with the provisions of Section 91 of the Town and Country Planning Act 1990 (as amended)."
      expect(page).not_to have_content "Condition 1"
      expect(page).not_to have_content "Reason 1"
    end

    it "shows errors" do
      click_link "Add conditions"

      check "Time limit"
      within(:css, "#standard-conditions .condition:nth-of-type(1)") do
        fill_in "Condition", with: ""
      end

      click_link "+ Add condition"
      within(:css, "#other-conditions .condition:nth-of-type(1)") do
        fill_in "Condition", with: "Custom condition 1"
      end

      click_button "Save and mark as complete"

      expect(page).to have_content "Conditions text can't be blank"
      expect(page).to have_content "Conditions reason can't be blank"
    end

    it "shows conditions on the decision notice" do
      create(:recommendation, :assessment_in_progress, planning_application:)
      create(:condition, condition_set: planning_application.condition_set, standard: true)

      visit planning_application_path(planning_application)
      click_link "Check and assess"
      click_link "Review and submit recommendation"

      expect(page).to have_content "Conditions"
      expect(page).to have_content "The development herby permitted shall be commenced within three years of the date of this permission."
      expect(page).to have_content "To comply with the provisions of Section 91 of the Town and Country Planning Act 1990 (as amended)."
    end
  end

  context "when planning application is not planning permission" do
    it "you cannot add conditions" do
      type = ApplicationType.find_by(name: "lawfulness_certificate")
      planning_application.update(application_type: type)

      visit planning_application_path(planning_application)
      click_link "Check and assess"

      expect(page).not_to have_content("Add conditions")
    end
  end
end
