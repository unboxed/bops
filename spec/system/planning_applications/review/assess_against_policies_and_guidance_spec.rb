# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reviewing assessment against policies and guidance", type: :system, js: true do
  let!(:local_authority) { create(:local_authority, :default) }
  let!(:api_user) { create(:api_user, local_authority:) }
  let!(:assessor) { create(:user, :assessor, local_authority:, name: "Anne Assessor") }
  let!(:reviewer) { create(:user, :reviewer, local_authority:, name: "Ray Reviewer") }
  let(:consideration_set) { planning_application.consideration_set }
  let(:current_review) { consideration_set.current_review }

  let!(:planning_application) do
    create(:planning_application, :planning_permission, :awaiting_determination, :with_recommendation, local_authority:)
  end

  before do
    create(:local_authority_policy_area, local_authority:, description: "Design")
    create(:local_authority_policy_reference, local_authority:, code: "PP100", description: "Wall materials")
    create(:local_authority_policy_reference, local_authority:, code: "PP101", description: "Roofing materials")
    create(:local_authority_policy_guidance, local_authority:, description: "Design Guidance")
  end

  context "when signed in as a reviewer" do
    before do
      travel_to Time.zone.local(2024, 7, 23, 11)

      sign_in(assessor)
      visit "/planning_applications/#{planning_application.id}/assessment/tasks"

      click_link "Assess against policies and guidance"
      expect(page).to have_selector("h1", text: "Assess against policies and guidance")

      fill_in "Enter policy area", with: "Design"
      pick "Design", from: "#consideration-policy-area-field"

      fill_in "Enter policy references", with: "Wall"
      pick "PP100 - Wall materials", from: "#policyReferencesAutoComplete"

      fill_in "Enter policy references", with: "Roofing"
      pick "PP101 - Roofing materials", from: "#policyReferencesAutoComplete"

      fill_in "Enter policy guidance", with: "Design"
      pick "Design Guidance", from: "#policyGuidanceAutoComplete"

      fill_in "Enter assessment", with: "Uses red brick with grey slates"
      fill_in "Enter conclusion", with: "Complies with design guidance policies"

      click_button "Add consideration"

      expect(page).to have_content("Consideration was successfully added")

      within "main ol" do
        within "li:nth-of-type(1)" do
          expect(page).to have_selector("h2", text: "Design")
        end
      end

      click_button "Save and mark as complete"
      expect(page).to have_content("Assessment against local policies was successfully saved")

      sign_in(reviewer)
      visit "/planning_applications/#{planning_application.id}/review/tasks"
    end

    it "I can accept the planning officer's decision" do
      expect(page).to have_list_item_for("Review assessment against policies and guidance", with: "Not started")

      click_link "Review assessment against policies and guidance"

      expect(page).to have_selector("h1", text: "Review assessment against policies and guidance")

      within_fieldset("Do you accept the assessment?") do
        choose "Yes"
      end

      expect(current_review).to have_attributes(action: nil, review_status: "review_not_started")

      click_button "Save and mark as complete"

      expect(page).to have_content("Review of assessment against policy and guidance updated successfully")
      expect(page).to have_list_item_for("Review assessment against policies and guidance", with: "Completed")

      expect(current_review.reload).to have_attributes(action: "accepted", review_status: "review_complete")

      click_link "Review assessment against policies and guidance"

      expect(page).to have_selector("h1", text: "Review assessment against policies and guidance")
      expect(page).to have_content("Assement against policies and guidance accepted by Ray Reviewer, 23 July 2024")
    end

    it "I can edit to accept the planning officer's decision" do
      expect(page).to have_list_item_for("Review assessment against policies and guidance", with: "Not started")

      click_link "Review assessment against policies and guidance"
      expect(page).to have_selector("h1", text: "Review assessment against policies and guidance")

      click_link "Edit to accept"
      expect(page).to have_selector("h1", text: "Edit consideration")

      fill_in "Enter assessment", with: "Uses yellow brick with grey slates"

      click_button "Save consideration"
      expect(page).to have_content("Consideration was successfully saved")

      within_fieldset("Do you accept the assessment?") do
        choose "Yes"
      end

      expect(current_review).to have_attributes(action: nil, review_status: "review_not_started")

      click_button "Save and mark as complete"

      expect(page).to have_content("Review of assessment against policy and guidance updated successfully")
      expect(page).to have_list_item_for("Review assessment against policies and guidance", with: "Completed")

      expect(current_review.reload).to have_attributes(action: "edited_and_accepted", review_status: "review_complete")

      click_link "Review assessment against policies and guidance"

      expect(page).to have_selector("h1", text: "Review assessment against policies and guidance")
      expect(page).to have_content("Assement against policies and guidance edited and accepted by Ray Reviewer, 23 July 2024")
    end

    it "I can return to the planning officer with a comment" do
      expect(page).to have_list_item_for("Review assessment against policies and guidance", with: "Not started")

      click_link "Review assessment against policies and guidance"

      expect(page).to have_selector("h1", text: "Review assessment against policies and guidance")

      within_fieldset("Do you accept the assessment?") do
        choose "No"
        fill_in "Enter comment", with: "Please provide more details about the design of the property"
      end

      expect(current_review).to have_attributes(action: nil, review_status: "review_not_started", comment: nil)

      click_button "Save and mark as complete"

      expect(page).to have_content("Review of assessment against policy and guidance updated successfully")
      expect(page).to have_list_item_for("Review assessment against policies and guidance", with: "Awaiting changes")

      expect(current_review.reload).to have_attributes(action: "rejected", review_status: "review_complete", comment: "Please provide more details about the design of the property")

      click_link "Review assessment against policies and guidance"

      expect(page).to have_selector("h1", text: "Review assessment against policies and guidance")
      expect(page).to have_content("Assement against policies and guidance rejected by Ray Reviewer, 23 July 2024")

      travel_to Time.zone.local(2024, 7, 23, 12)
      sign_in(assessor)

      visit "/planning_applications/#{planning_application.id}/assessment/tasks"
      expect(page).to have_list_item_for("Assess against policies and guidance", with: "To be reviewed")

      click_link "Assess against policies and guidance"

      expect(page).to have_selector("h1", text: "Assess against policies and guidance")
      expect(page).to have_content("Please provide more details about the design of the property")
      expect(page).to have_content("Sent on 23 July 2024 11:00 by Ray Reviewer")

      click_link "Edit"
      expect(page).to have_selector("h1", text: "Edit consideration")

      fill_in "Enter assessment", with: "Uses yellow brick with grey slates"

      click_button "Save consideration"
      expect(page).to have_content("Consideration was successfully saved")

      click_button "Save and mark as complete"
      expect(page).to have_content("Assessment against local policies was successfully saved")
      expect(page).to have_list_item_for("Assess against policies and guidance", with: "Updated")

      travel_to Time.zone.local(2024, 7, 23, 13)
      sign_in(reviewer)

      visit "/planning_applications/#{planning_application.id}/review/tasks"
      expect(page).to have_list_item_for("Review assessment against policies and guidance", with: "Updated")

      click_link "Review assessment against policies and guidance"

      expect(page).to have_selector("h1", text: "Review assessment against policies and guidance")

      within_fieldset("Do you accept the assessment?") do
        choose "Yes"
      end

      click_button "Save and mark as complete"
      expect(page).to have_content("Review of assessment against policy and guidance updated successfully")
      expect(page).to have_list_item_for("Review assessment against policies and guidance", with: "Completed")

      click_link "Review assessment against policies and guidance"
      expect(page).to have_selector("h1", text: "Review assessment against policies and guidance")
      expect(page).to have_content("Assement against policies and guidance accepted by Ray Reviewer, 23 July 2024")
    end
  end
end
