# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Make draft recommendation task", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:assessor) { create(:user, :assessor, local_authority:) }
  let(:task) do
    planning_application.case_record.find_task_by_slug_path!(
      "check-and-assess/complete-assessment/make-draft-recommendation"
    )
  end
  let(:task_path) do
    "/planning_applications/#{planning_application.reference}" \
      "/check-and-assess/complete-assessment/make-draft-recommendation"
  end
  let(:planning_application) do
    create(:planning_application, :planning_permission, :in_assessment, local_authority:, public_comment: nil)
  end

  before do
    create(:decision, :householder_granted)
    create(:decision, :householder_refused)
    sign_in assessor
    visit "/planning_applications/#{planning_application.reference}"
    click_link "Check and assess"
  end

  context "when viewing the make draft recommendation task" do
    it "can be navigated to from the sidebar" do
      within ".bops-sidebar" do
        click_link "Make draft recommendation"
      end

      expect(page).to have_current_path("/planning_applications/#{planning_application.reference}/check-and-assess/complete-assessment/make-draft-recommendation")
      expect(page).to have_selector("h1", text: "Make draft recommendation")
    end
  end

  context "when saving and marking as complete" do
    before do
      within ".bops-sidebar" do
        click_link "Make draft recommendation"
      end
    end

    it "saves all fields and completes the task" do
      within_fieldset("Does this planning application need to be decided by committee?") do
        choose "No"
      end

      within_fieldset("What is your recommendation?") do
        choose "Granted"
      end

      fill_in "State the reasons for your recommendation.", with: "The proposal meets all policy requirements."
      fill_in "Provide supporting information for the reviewer.", with: "No issues identified."

      click_button "Save and mark as complete"

      planning_application.reload
      expect(planning_application.decision).to eq("granted")
      expect(planning_application.public_comment).to eq("The proposal meets all policy requirements.")
      expect(planning_application.recommendations.last.assessor_comment).to eq("No issues identified.")
      expect(planning_application.recommendations.last.status).to eq("assessment_complete")
      expect(task.reload).to be_completed
    end

    it "shows validation errors when required fields are blank" do
      click_button "Save and mark as complete"

      expect(page).to have_content("Select whether the application needs to be decided by committee.")
      expect(page).to have_selector(".govuk-error-summary")
    end

    it "requires reasons when committee is needed" do
      within_fieldset("Does this planning application need to be decided by committee?") do
        choose "Yes"
      end

      within_fieldset("What is your recommendation?") do
        choose "Granted"
      end

      fill_in "State the reasons for your recommendation.", with: "Public comment"

      click_button "Save and mark as complete"

      expect(page).to have_content("Explain why the application needs to be decided by committee")
    end
  end

  context "when saving as a draft" do
    before do
      within ".bops-sidebar" do
        click_link "Make draft recommendation"
      end
    end

    it "saves data and keeps the task in progress" do
      within_fieldset("Does this planning application need to be decided by committee?") do
        choose "No"
      end

      within_fieldset("What is your recommendation?") do
        choose "Granted"
      end

      fill_in "State the reasons for your recommendation.", with: "This is a public comment"
      fill_in "Provide supporting information for the reviewer.", with: "This is a private assessor comment"

      click_button "Save changes"

      planning_application.reload
      expect(planning_application.public_comment).to eq("This is a public comment")
      expect(planning_application.recommendations.last.assessor_comment).to eq("This is a private assessor comment")
      expect(planning_application.recommendations.last.status).to eq("assessment_in_progress")
      expect(task.reload).to be_in_progress
    end

    it "does not show errors when no decision is given" do
      click_button "Save changes"

      expect(page).not_to have_content("Select whether the application needs to be decided by committee.")
      expect(planning_application.reload.status).to eq("in_assessment")
    end
  end

  context "when existing recommendation and committee decision data is present" do
    before do
      create(
        :recommendation,
        :assessment_in_progress,
        planning_application:,
        assessor:,
        assessor_comment: "Existing assessor comment"
      )
      planning_application.update!(decision: "granted", public_comment: "Existing public comment")
      create(
        :committee_decision,
        planning_application:,
        recommend: true,
        reasons: ["The application is on council owned land", "Custom other reason"]
      )
      task.start!

      within ".bops-sidebar" do
        click_link "Make draft recommendation"
      end
    end

    it "pre-populates all form fields from existing records" do
      within_fieldset("Does this planning application need to be decided by committee?") do
        expect(page).to have_checked_field("Yes")
      end

      expect(page).to have_checked_field("The application is on council owned land")
      expect(page).to have_field(
        "Tell reviewer and the public why the application needs to go to committee.",
        with: "Custom other reason"
      )

      within_fieldset("What is your recommendation?") do
        expect(page).to have_checked_field("Granted")
      end

      expect(page).to have_field(
        "State the reasons for your recommendation.",
        with: "Existing public comment"
      )
      expect(page).to have_field(
        "Provide supporting information for the reviewer.",
        with: "Existing assessor comment"
      )
    end
  end

  context "when the application needs to go to committee" do
    before do
      within ".bops-sidebar" do
        click_link "Make draft recommendation"
      end
    end

    it "creates a committee decision with reasons" do
      within_fieldset("Does this planning application need to be decided by committee?") do
        choose "Yes"
      end

      check "The application is on council owned land"
      check "Other"
      fill_in "Tell reviewer and the public why the application needs to go to committee.", with: "Another reason"

      within_fieldset("What is your recommendation?") do
        choose "Granted"
      end

      fill_in "State the reasons for your recommendation.", with: "Public comment"

      click_button "Save and mark as complete"

      committee_decision = planning_application.reload.committee_decision
      expect(committee_decision.recommend).to be(true)
      expect(committee_decision.reasons).to include("The application is on council owned land")
      expect(committee_decision.reasons).to include("Another reason")
      expect(task.reload).to be_completed
    end
  end

  context "when a return_to param is present" do
    let(:assessment_tasks_path) do
      "/planning_applications/#{planning_application.reference}/assessment/tasks"
    end

    it "redirects to the return_to URL after saving" do
      visit "#{task_path}?return_to=#{assessment_tasks_path}"

      within_fieldset("Does this planning application need to be decided by committee?") do
        choose "No"
      end

      within_fieldset("What is your recommendation?") do
        choose "Granted"
      end

      fill_in "State the reasons for your recommendation.", with: "Public comment"

      click_button "Save and mark as complete"

      expect(page).to have_current_path(assessment_tasks_path, ignore_query: true)
    end
  end
end
