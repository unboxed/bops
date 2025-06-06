# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Add conditions", type: :system, capybara: true do
  let(:default_local_authority) { create(:local_authority, :default) }
  let!(:api_user) { create(:api_user, :planx, local_authority: default_local_authority) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  let(:planning_application) do
    create(:planning_application, :planning_permission, :in_assessment, :with_condition_set, local_authority: default_local_authority, api_user:, decision: "granted")
  end

  let(:reference) { planning_application.reference }

  before do
    sign_in assessor
    visit "/planning_applications/#{reference}"
    click_link "Check and assess"
  end

  context "when planning application is planning permission" do
    it "you can add conditions" do
      click_link "Add conditions"
      expect(page).to have_content("Add conditions")

      toggle "Add condition"

      fill_in "Enter condition", with: "New condition"
      fill_in "Enter a reason for this condition", with: "No reason"

      click_button "Add condition to list"
      expect(page).to have_current_path("/planning_applications/#{reference}/assessment/conditions")
      expect(page).to have_content("Conditions successfully updated")

      toggle "Add condition"

      fill_in "Enter condition", with: "Custom condition 1"
      fill_in "Enter a reason for this condition", with: "Custom reason 1"

      click_button "Add condition to list"
      expect(page).to have_current_path("/planning_applications/#{reference}/assessment/conditions")
      expect(page).to have_content("Conditions successfully updated")

      toggle "Add condition"

      fill_in "Enter condition", with: "Custom condition 2"
      fill_in "Enter a reason for this condition", with: "Custom reason 2"

      click_button "Add condition to list"
      expect(page).to have_current_path("/planning_applications/#{reference}/assessment/conditions")
      expect(page).to have_content("Conditions successfully updated")

      toggle "Add condition"

      fill_in "Enter condition", with: "Custom condition 3"
      fill_in "Enter a reason for this condition", with: "Custom reason 3"
      # n.b. form not submitted here
      toggle "Add condition"

      click_button "Save and mark as complete"
      expect(page).to have_current_path("/planning_applications/#{reference}/assessment/tasks")
      expect(page).to have_content("Conditions successfully updated")

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
      create(:condition, condition_set: planning_application.condition_set, standard: false, title: "", text: "You must do this", reason: "For this reason")

      visit "/planning_applications/#{reference}"
      click_link "Check and assess"

      click_link "Add conditions"

      expect(page).to have_content "Time limit"
      expect(page).to have_content "The development hereby permitted shall be commenced within three years of the date of this permission."
      expect(page).to have_content "To comply with the provisions of Section 91 of the Town and Country Planning Act 1990 (as amended)."
      expect(page).to have_content "You must do this"
      expect(page).to have_content "For this reason"

      toggle "Add condition"
      fill_in "Enter condition", with: "Custom condition 1"
      fill_in "Enter a reason for this condition", with: "Custom reason 1"
      click_button "Add condition to list"

      expect(page).to have_content "Time limit"
      expect(page).to have_content "The development hereby permitted shall be commenced within three years of the date of this permission."
      expect(page).to have_content "To comply with the provisions of Section 91 of the Town and Country Planning Act 1990 (as amended)."
      expect(page).to have_content "In accordance with approved plans"
      expect(page).to have_content "The development hereby permitted must be undertaken in accordance with the approved plans and documents."
      expect(page).to have_content "For the avoidance of doubt and in the interests of proper planning."
      expect(page).to have_content "You must do this"
      expect(page).to have_content "For this reason"
      expect(page).to have_content "Custom condition 1"
      expect(page).to have_content "Custom reason 1"
    end

    it "you can delete conditions" do
      visit "/planning_applications/#{reference}"
      click_link "Check and assess"

      click_link "Add conditions"

      accept_confirm do
        within(:css, "#conditions-list li:nth-of-type(1)") do
          click_link "Remove"
        end
      end

      accept_confirm do
        within(:css, "#conditions-list li:nth-of-type(2)") do
          click_link "Remove"
        end
      end

      dismiss_confirm do
        within(:css, "#conditions-list li:nth-of-type(1)") do
          click_link "Remove"
        end
      end

      expect(page).to have_content "In accordance with approved plans"
      expect(page).to have_content "The development hereby permitted must be undertaken in accordance with the approved plans and documents."
      expect(page).to have_content "For the avoidance of doubt and in the interests of proper planning."

      expect(page).not_to have_content "Time limit"
      expect(page).not_to have_content "The development hereby permitted shall be commenced within three years of the date of this permission."
      expect(page).not_to have_content "To comply with the provisions of Section 91 of the Town and Country Planning Act 1990 (as amended)."

      expect(page).not_to have_content "Materials to match"
      expect(page).not_to have_content "All new external work and finishes and work of making good shall match the original work in respect of the materials, colour, texture, profile and finished appearance, except where indicated otherwise on the drawings hereby approved or unless otherwise required by condition."
      expect(page).not_to have_content "To preserve the character and appearance of the local area."
    end

    it "shows errors when adding" do
      click_link "Add conditions"

      toggle "Add condition"
      fill_in "Enter condition", with: "Custom condition 1"

      click_button "Add condition to list"

      within ".govuk-error-summary" do
        expect(page).to have_content "Enter the reason for this condition"
      end
    end

    it "shows errors when editing" do
      click_link "Add conditions"

      within(:css, "#conditions-list li:first-of-type") do
        click_link "Edit"
      end

      fill_in "Enter condition", with: ""
      click_button "Add condition to list"

      within ".govuk-error-summary" do
        expect(page).to have_content "Enter the text of this condition"
      end
    end

    it "shows conditions on the decision notice" do
      create(:recommendation, :assessment_in_progress, planning_application:)
      create(:condition, condition_set: planning_application.condition_set, standard: true)

      visit "/planning_applications/#{reference}"
      click_link "Check and assess"
      click_link "Review and submit recommendation"

      expect(page).to have_content "Conditions"
      expect(page).to have_content "The development hereby permitted shall be commenced within three years of the date of this permission."
      expect(page).to have_content "To comply with the provisions of Section 91 of the Town and Country Planning Act 1990 (as amended)."
    end

    context "when there is no current review" do
      let(:condition_set) { planning_application.condition_set }

      before do
        condition_set.reviews = []
      end

      it "doesn't break" do
        visit "/planning_applications/#{reference}"
        click_link "Check and assess"

        click_link "Add conditions"
        click_button "Save and mark as complete"
      end
    end
  end

  context "when changing the list position" do
    let(:condition_set) { planning_application.condition_set }
    let!(:condition_one) { create(:condition, :nonstandard, condition_set:, title: "Title 1", text: "Text 1", position: 1) }
    let!(:condition_two) { create(:condition, :other, :nonstandard, condition_set:, title: "Title 2", text: "Text 2", position: 2) }
    let!(:condition_three) { create(:condition, :nonstandard, condition_set:, title: "Title 3", text: "Text 3", position: 3) }

    before do
      condition_set.conditions.where(standard: true).delete_all
      click_link "Add conditions"
    end

    include_examples "Sortable", "condition"
  end

  context "when planning application is not planning permission" do
    let(:planning_application) do
      create(:planning_application, :ldc_proposed, :in_assessment, local_authority: default_local_authority, api_user:, decision: "granted")
    end

    it "you cannot add conditions" do
      visit "/planning_applications/#{reference}"
      click_link "Check and assess"

      expect(page).not_to have_content("Add conditions")
    end
  end
end
