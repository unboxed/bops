# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Review and submit recommendation task", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:assessor) { create(:user, :assessor, local_authority:) }
  let(:planning_application) do
    create(:planning_application, :planning_permission, :in_assessment, local_authority:,
      decision: "granted", public_comment: "The proposal meets all policy requirements.")
  end
  let(:make_draft_recommendation_task) do
    planning_application.case_record.find_task_by_slug_path!(
      "check-and-assess/complete-assessment/make-draft-recommendation"
    )
  end
  let(:task) do
    planning_application.case_record.find_task_by_slug_path!(
      "check-and-assess/complete-assessment/review-and-submit-recommendation"
    )
  end

  before do
    create(:decision, :householder_granted)
    create(:decision, :householder_refused)
    create(:recommendation, :assessment_complete, planning_application:, assessor:)
    make_draft_recommendation_task.complete!
    sign_in assessor
    visit "/planning_applications/#{planning_application.reference}"
    click_link "Check and assess"
  end

  context "when viewing the review and submit recommendation task" do
    it "can be navigated to from the sidebar" do
      within ".bops-sidebar" do
        click_link "Review and submit recommendation"
      end

      expect(page).to have_current_path("/planning_applications/#{planning_application.reference}/check-and-assess/complete-assessment/review-and-submit-recommendation")
      expect(page).to have_selector("h1", text: "Review and submit recommendation")
    end
  end

  context "when viewing the page before submission" do
    before do
      within ".bops-sidebar" do
        click_link "Review and submit recommendation"
      end
    end

    it "shows the submit heading and edit recommendation link" do
      expect(page).to have_selector("h2", text: "Submit recommendation")
      expect(page).to have_link("Edit recommendation")
      expect(page).not_to have_button("Withdraw recommendation")
    end
  end

  context "when submitting the recommendation" do
    before do
      within ".bops-sidebar" do
        click_link "Review and submit recommendation"
      end
    end

    it "submits the recommendation and completes the task" do
      click_button "Save and mark as complete"

      expect(page).to have_content("Successfully submitted recommendation for review")
      expect(planning_application.reload.status).to eq("awaiting_determination")
      expect(task.reload).to be_completed
    end
  end

  context "when withdrawing a submitted recommendation" do
    before do
      within ".bops-sidebar" do
        click_link "Review and submit recommendation"
      end
      click_button "Save and mark as complete"

      within ".bops-sidebar" do
        click_link "Review and submit recommendation"
      end
    end

    it "shows the withdraw button and hides the edit link" do
      expect(page).not_to have_link("Edit recommendation")
      expect(page).to have_button("Withdraw recommendation")
    end

    it "withdraws the recommendation" do
      click_button "Withdraw recommendation"

      expect(page).to have_content("Recommendation successfully withdrawn")
      expect(planning_application.reload.status).to eq("in_assessment")
      expect(task.reload).to be_in_progress
    end
  end

  context "when there are open post-validation requests" do
    before do
      create(:red_line_boundary_change_validation_request, :post_validation, :open, planning_application:)

      within ".bops-sidebar" do
        click_link "Review and submit recommendation"
      end
    end

    it "displays an error message" do
      click_button "Save and mark as complete"
      expect(page).to have_content("All post-validation requests must be resolved before submitting")
    end
  end
end
