# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Pre-application assessment workflow", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:assessor) { create(:user, :assessor, local_authority:, name: "Alice Smith") }
  let(:reviewer) { create(:user, :reviewer, local_authority:, name: "Bob Jones") }
  let(:case_record) { build(:case_record, user: assessor, local_authority:) }

  let!(:requirement) { create(:local_authority_requirement, local_authority:, category: "drawings", description: "Floor plans") }
  let!(:application_type) { create(:application_type, :prior_approval, local_authority:, requirements: [requirement]) }
  let!(:policy_area) { create(:local_authority_policy_area, local_authority:, description: "Design") }
  let!(:policy_reference) { create(:local_authority_policy_reference, local_authority:, code: "LP1", description: "Local design policy") }

  let(:planning_application) do
    create(:planning_application, :pre_application, :in_assessment,
      local_authority:,
      case_record:,
      recommended_application_type: application_type)
  end

  let(:reference) { planning_application.reference }

  describe "end-to-end assessment workflow" do
    it "completes all assessment tasks in sequence with correct status transitions and icons" do
      sign_in(assessor)
      visit "/planning_applications/#{reference}/assessment/tasks"

      expect(page).to have_selector(:sidebar)
      expect(page).to have_content("Assessment")

      within :sidebar do
        expect(page).to have_content("Check application")
        expect(page).to have_content("Additional services")
        expect(page).to have_content("Assessment summaries")
        expect(page).to have_content("Complete assessment")
      end

      assessment_tasks.each do |t|
        expect(t).to be_not_started
      end

      within :sidebar do
        expect(page).to have_css("svg[aria-label='Not started']", minimum: 10)
      end

      within :sidebar do
        click_link "Check application details"
      end

      expect(page).to have_current_path("/preapps/#{reference}/check-and-assess/check-application/check-application-details")
      expect(page).to have_selector("h1", text: "Check application details")
      expect(page).to have_selector(:active_sidebar_task, "Check application details")

      within_fieldset("Does the description match the development or use in the plans?") { choose "Yes" }
      within_fieldset("Are the plans consistent with each other?") { choose "Yes" }
      within_fieldset("Are the proposal details consistent with the plans?") { choose "Yes" }
      within_fieldset("Is the site map correct?") { choose "Yes" }

      click_button "Save and mark as complete"

      expect(task("Check application details").reload).to be_completed
      expect(page).to have_selector(:completed_sidebar_task, "Check application details")

      within :sidebar do
        click_link "Check consultees consulted"
      end

      expect(page).to have_current_path("/preapps/#{reference}/check-and-assess/check-application/check-consultees-consulted")
      expect(page).to have_selector("h1", text: "Check consultees consulted")
      expect(page).to have_selector(:active_sidebar_task, "Check consultees consulted")

      click_button "Save and mark as complete"

      expect(task("Check consultees consulted").reload).to be_completed
      expect(page).to have_selector(:completed_sidebar_task, "Check consultees consulted")

      within :sidebar do
        click_link "Check site history"
      end

      expect(page).to have_current_path("/preapps/#{reference}/check-and-assess/check-application/check-site-history")
      expect(page).to have_selector("h1", text: "Check site history")
      expect(page).to have_selector(:active_sidebar_task, "Check site history")

      click_button "Save and mark as complete"

      expect(task("Check site history").reload).to be_completed
      expect(page).to have_selector(:completed_sidebar_task, "Check site history")

      within :sidebar do
        click_link "Site visit"
      end

      expect(page).to have_current_path("/preapps/#{reference}/check-and-assess/additional-services/site-visit")
      expect(page).to have_selector("h1", text: "Site visit")
      expect(page).to have_selector(:active_sidebar_task, "Site visit")

      expect(page).to have_content("No site visits have been recorded yet")

      click_button "Save and mark as complete"

      expect(task("Site visit").reload).to be_completed
      expect(page).to have_selector(:completed_sidebar_task, "Site visit")

      within :sidebar do
        click_link "Meeting"
      end

      expect(page).to have_current_path("/preapps/#{reference}/check-and-assess/additional-services/meeting")
      expect(page).to have_selector("h1", text: "Meeting")
      expect(page).to have_selector(:active_sidebar_task, "Meeting")

      click_button "Save and mark as complete"

      expect(task("Meeting").reload).to be_completed
      expect(page).to have_selector(:completed_sidebar_task, "Meeting")

      within :sidebar do
        click_link "Site description"
      end

      expect(page).to have_current_path("/preapps/#{reference}/check-and-assess/assessment-summaries/site-description")
      expect(page).to have_selector("h1", text: "Site description")
      expect(page).to have_selector(:active_sidebar_task, "Site description")

      fill_in "Description of the site", with: "A detached house with garden."

      click_button "Save changes"

      expect(page).to have_content("Site description was successfully updated")
      expect(task("Site description").reload).to be_in_progress
      expect(page).to have_selector(:in_progress_sidebar_task, "Site description")

      click_button "Save and mark as complete"

      expect(task("Site description").reload).to be_completed
      expect(page).to have_selector(:completed_sidebar_task, "Site description")

      within :sidebar do
        click_link "Planning considerations and advice"
      end

      expect(page).to have_current_path("/preapps/#{reference}/check-and-assess/assessment-summaries/planning-considerations-and-advice")
      expect(page).to have_selector("h1", text: "Planning considerations and advice")
      expect(page).to have_selector(:active_sidebar_task, "Planning considerations and advice")

      click_button "Save and mark as complete"

      expect(task("Planning considerations and advice").reload).to be_completed
      expect(page).to have_selector(:completed_sidebar_task, "Planning considerations and advice")

      within :sidebar do
        click_link "Suggest heads of terms"
      end

      expect(page).to have_current_path("/preapps/#{reference}/check-and-assess/assessment-summaries/suggest-heads-of-terms")
      expect(page).to have_selector("h1", text: "Suggest heads of terms")
      expect(page).to have_selector(:active_sidebar_task, "Suggest heads of terms")

      click_button "Save and mark as complete"

      expect(task("Suggest heads of terms").reload).to be_completed
      expect(page).to have_selector(:completed_sidebar_task, "Suggest heads of terms")

      within :sidebar do
        click_link "Summary of advice"
      end

      expect(page).to have_current_path("/preapps/#{reference}/check-and-assess/assessment-summaries/summary-of-advice")
      expect(page).to have_selector("h1", text: "Summary of advice")
      expect(page).to have_selector(:active_sidebar_task, "Summary of advice")

      choose "Likely to be supported (recommended based on considerations)"
      fill_in "Enter summary of planning considerations and advice. This should summarise any changes the applicant needs to make before they make an application.", with: "The proposal is acceptable."

      click_button "Save and mark as complete"

      expect(page).to have_content("Summary of advice successfully updated")
      expect(task("Summary of advice").reload).to be_completed
      expect(page).to have_selector(:completed_sidebar_task, "Summary of advice")

      within :sidebar do
        click_link "Choose application type"
      end

      expect(page).to have_current_path("/preapps/#{reference}/check-and-assess/complete-assessment/choose-application-type")
      expect(page).to have_selector("h1", text: "Choose application type")
      expect(page).to have_selector(:active_sidebar_task, "Choose application type")

      expect(page).to have_content("What application type would the applicant need to apply for next?")

      select "Prior Approval - Larger extension to a house", from: "What application type would the applicant need to apply for next?"
      click_button "Save and mark as complete"

      expect(page).to have_content("Recommended application type was successfully chosen")
      expect(task("Choose application type").reload).to be_completed
      expect(page).to have_selector(:completed_sidebar_task, "Choose application type")

      within :sidebar do
        click_link "Check and add requirements"
      end

      expect(page).to have_current_path("/preapps/#{reference}/check-and-assess/complete-assessment/check-and-add-requirements")
      expect(page).to have_selector("h1", text: "Check and add requirements")
      expect(page).to have_selector(:active_sidebar_task, "Check and add requirements")

      click_button "Save and mark as complete"

      expect(page).to have_content("Requirements were successfully saved")
      expect(task("Check and add requirements").reload).to be_completed
      expect(page).to have_selector(:completed_sidebar_task, "Check and add requirements")

      within :sidebar do
        click_link "Review and submit pre-application"
      end

      expect(page).to have_selector("h1", text: "Pre-application report")

      click_button "Confirm and submit recommendation"

      expect(page).to have_content("Pre-application report submitted for review")
      expect(task("Review and submit pre-application").reload).to be_completed
    end

    it "hides buttons when application is determined" do
      planning_application.update!(status: "determined", determined_at: Time.current)

      sign_in(assessor)
      visit "/preapps/#{reference}/check-and-assess/assessment-summaries/site-description"

      expect(page).not_to have_button("Save and mark as complete")
      expect(page).not_to have_button("Save changes")
    end

    it "maintains sidebar scroll position across navigation", js: true do
      sign_in(assessor)
      visit "/planning_applications/#{reference}/assessment/tasks"

      expect(page).to have_selector(:sidebar)

      within :sidebar do
        click_link "Summary of advice"
      end

      expect(page).to have_css("nav.bops-sidebar[data-controller='sidebar-scroll']")

      initial_scroll = page.evaluate_script("document.querySelector('nav.bops-sidebar').scrollTop")

      within :sidebar do
        click_link "Check application details"
      end

      final_scroll = page.evaluate_script("document.querySelector('nav.bops-sidebar').scrollTop")
      expect(final_scroll).to eq(initial_scroll)
    end
  end

  describe "review and submit workflow with reviewer" do
    before do
      planning_application.case_record.update!(user: assessor)
      create(:assessment_detail, planning_application:, category: :summary_of_work, entry: "Test summary")
      create(:assessment_detail, planning_application:, category: :site_description, entry: "Test site")
      create(:assessment_detail, planning_application:, category: :consultation_summary, entry: "Test consultation")
      planning_application.create_consideration_set! if planning_application.consideration_set.nil?
    end

    it "handles the full review workflow with action_required status" do
      sign_in(assessor)
      visit "/planning_applications/#{reference}/assessment/tasks"

      expect(page).to have_selector(:sidebar)

      within :sidebar do
        click_link "Review and submit pre-application"
      end

      expect(task("Review and submit pre-application")).to be_not_started

      click_button "Confirm and submit recommendation"

      expect(page).to have_content("Pre-application report submitted for review")
      expect(task("Review and submit pre-application").reload).to be_completed

      sign_out(assessor)
      sign_in(reviewer)

      visit "/reports/planning_applications/#{reference}?origin=review_and_submit_pre_application"

      within_fieldset "Do you agree with the advice?" do
        choose "No (return the case for assessment)"
        fill_in "Reviewer comment", with: "Needs more detail on considerations"
      end

      click_button "Confirm and submit pre-application report"

      expect(page).to have_content("Pre-application report has been sent back to the case officer for amendments")
      expect(task("Review and submit pre-application").reload).to be_action_required

      sign_out(reviewer)
      sign_in(assessor)

      visit "/planning_applications/#{reference}/assessment/tasks"

      expect(page).to have_selector(:action_required_sidebar_task, "Review and submit pre-application")

      within :sidebar do
        click_link "Review and submit pre-application"
      end

      fill_in "Assessor comment", with: "Added the requested details"
      click_button "Confirm and submit recommendation"

      expect(page).to have_content("Pre-application report submitted for review")
      expect(task("Review and submit pre-application").reload).to be_completed

      sign_out(assessor)
      sign_in(reviewer)

      visit "/reports/planning_applications/#{reference}?origin=review_and_submit_pre_application"

      within_fieldset "Do you agree with the advice?" do
        choose "Yes"
      end

      click_button "Confirm and submit pre-application report"

      expect(page).to have_content("Pre-application report has been sent to the applicant")
      expect(task("Review and submit pre-application").reload).to be_completed
    end
  end
end
