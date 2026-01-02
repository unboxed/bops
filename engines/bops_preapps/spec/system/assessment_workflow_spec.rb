# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Pre-application assessment workflow", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:assessor) { create(:user, :assessor, local_authority:, name: "Alice Smith") }
  let(:reviewer) { create(:user, :reviewer, local_authority:, name: "Bob Jones") }
  let(:case_record) { build(:case_record, user: assessor, local_authority:) }

  let!(:application_type) { create(:application_type, :prior_approval, local_authority:) }
  let!(:requirement) { create(:local_authority_requirement, local_authority:, category: "drawings", description: "Floor plans") }
  let!(:policy_area) { create(:local_authority_policy_area, local_authority:, description: "Design") }
  let!(:policy_reference) { create(:local_authority_policy_reference, local_authority:, code: "LP1", description: "Local design policy") }

  let(:planning_application) do
    create(:planning_application, :pre_application, :in_assessment,
      local_authority:,
      case_record:,
      recommended_application_type: application_type)
  end

  before do
    application_type.update!(requirements: [requirement])
  end

  describe "end-to-end assessment workflow" do
    it "completes all assessment tasks in sequence with correct status transitions and icons" do
      sign_in(assessor)
      visit "/planning_applications/#{planning_application.reference}/assessment/tasks"

      expect(page).to have_css(".bops-sidebar")
      expect(page).to have_content("Assessment")

      within ".bops-sidebar" do
        expect(page).to have_content("Check application")
        expect(page).to have_content("Additional services")
        expect(page).to have_content("Assessment summaries")
        expect(page).to have_content("Complete assessment")
      end

      check_app_details_task = planning_application.case_record.find_task_by_slug_path!("check-and-assess/check-application/check-application-details")
      check_consultees_task = planning_application.case_record.find_task_by_slug_path!("check-and-assess/check-application/check-consultees-consulted")
      check_site_history_task = planning_application.case_record.find_task_by_slug_path!("check-and-assess/check-application/check-site-history")
      site_visit_task = planning_application.case_record.find_task_by_slug_path!("check-and-assess/additional-services/site-visit")
      meeting_task = planning_application.case_record.find_task_by_slug_path!("check-and-assess/additional-services/meeting")
      site_description_task = planning_application.case_record.find_task_by_slug_path!("check-and-assess/assessment-summaries/site-description")
      considerations_task = planning_application.case_record.find_task_by_slug_path!("check-and-assess/assessment-summaries/planning-considerations-and-advice")
      heads_of_terms_task = planning_application.case_record.find_task_by_slug_path!("check-and-assess/assessment-summaries/suggest-heads-of-terms")
      summary_of_advice_task = planning_application.case_record.find_task_by_slug_path!("check-and-assess/assessment-summaries/summary-of-advice")
      choose_type_task = planning_application.case_record.find_task_by_slug_path!("check-and-assess/complete-assessment/choose-application-type")
      requirements_task = planning_application.case_record.find_task_by_slug_path!("check-and-assess/complete-assessment/check-and-add-requirements")
      review_submit_task = planning_application.case_record.find_task_by_slug_path!("check-and-assess/complete-assessment/review-and-submit-pre-application")

      expect(check_app_details_task).to be_not_started
      expect(check_consultees_task).to be_not_started
      expect(check_site_history_task).to be_not_started
      expect(site_visit_task).to be_not_started
      expect(meeting_task).to be_not_started
      expect(site_description_task).to be_not_started
      expect(considerations_task).to be_not_started
      expect(heads_of_terms_task).to be_not_started
      expect(summary_of_advice_task).to be_not_started
      expect(choose_type_task).to be_not_started
      expect(requirements_task).to be_not_started
      expect(review_submit_task).to be_not_started

      within ".bops-sidebar" do
        expect(page).to have_css("svg[aria-label='Not started']", minimum: 10)
      end

      within ".bops-sidebar" do
        click_link "Check application details"
      end

      expect(page).to have_current_path("/preapps/#{planning_application.reference}/check-and-assess/check-application/check-application-details")
      expect(page).to have_selector("h1", text: "Check application details")

      within ".bops-sidebar" do
        expect(page).to have_css(".bops-sidebar__task--active", text: "Check application details")
        expect(page).to have_css("a[aria-current='page']", text: "Check application details")
      end

      within_fieldset("Does the description match the development or use in the plans?") { choose "Yes" }
      within_fieldset("Are the plans consistent with each other?") { choose "Yes" }
      within_fieldset("Are the proposal details consistent with the plans?") { choose "Yes" }
      within_fieldset("Is the site map correct?") { choose "Yes" }

      click_button "Save and mark as complete"

      expect(check_app_details_task.reload).to be_completed

      within ".bops-sidebar" do
        within(".bops-sidebar__task", text: "Check application details") do
          expect(page).to have_css("svg[aria-label='Completed']")
        end
      end

      within ".bops-sidebar" do
        click_link "Check consultees consulted"
      end

      expect(page).to have_current_path("/preapps/#{planning_application.reference}/check-and-assess/check-application/check-consultees-consulted")
      expect(page).to have_selector("h1", text: "Check consultees consulted")

      within ".bops-sidebar" do
        expect(page).to have_css(".bops-sidebar__task--active", text: "Check consultees consulted")
      end

      click_button "Save and mark as complete"

      expect(check_consultees_task.reload).to be_completed

      within ".bops-sidebar" do
        within(".bops-sidebar__task", text: "Check consultees consulted") do
          expect(page).to have_css("svg[aria-label='Completed']")
        end
      end

      within ".bops-sidebar" do
        click_link "Check site history"
      end

      expect(page).to have_current_path("/preapps/#{planning_application.reference}/check-and-assess/check-application/check-site-history")
      expect(page).to have_selector("h1", text: "Check site history")

      within ".bops-sidebar" do
        expect(page).to have_css(".bops-sidebar__task--active", text: "Check site history")
      end

      click_button "Save and mark as complete"

      expect(check_site_history_task.reload).to be_completed

      within ".bops-sidebar" do
        within(".bops-sidebar__task", text: "Check site history") do
          expect(page).to have_css("svg[aria-label='Completed']")
        end
      end

      within ".bops-sidebar" do
        click_link "Site visit"
      end

      expect(page).to have_current_path("/preapps/#{planning_application.reference}/check-and-assess/additional-services/site-visit")
      expect(page).to have_selector("h1", text: "Site visit")

      within ".bops-sidebar" do
        expect(page).to have_css(".bops-sidebar__task--active", text: "Site visit")
      end

      expect(page).to have_content("No site visits have been recorded yet")

      click_button "Save and mark as complete"

      expect(site_visit_task.reload).to be_completed

      within ".bops-sidebar" do
        within(".bops-sidebar__task", text: "Site visit") do
          expect(page).to have_css("svg[aria-label='Completed']")
        end
      end

      within ".bops-sidebar" do
        click_link "Meeting"
      end

      expect(page).to have_current_path("/preapps/#{planning_application.reference}/check-and-assess/additional-services/meeting")
      expect(page).to have_selector("h1", text: "Meeting")

      within ".bops-sidebar" do
        expect(page).to have_css(".bops-sidebar__task--active", text: "Meeting")
      end

      click_button "Save and mark as complete"

      expect(meeting_task.reload).to be_completed

      within ".bops-sidebar" do
        within(".bops-sidebar__task", text: "Meeting") do
          expect(page).to have_css("svg[aria-label='Completed']")
        end
      end

      within ".bops-sidebar" do
        click_link "Site description"
      end

      expect(page).to have_current_path("/preapps/#{planning_application.reference}/check-and-assess/assessment-summaries/site-description")
      expect(page).to have_selector("h1", text: "Site description")

      within ".bops-sidebar" do
        expect(page).to have_css(".bops-sidebar__task--active", text: "Site description")
      end

      fill_in "Description of the site", with: "A detached house with garden."

      click_button "Save changes"

      expect(page).to have_content("Site description was successfully updated")
      expect(site_description_task.reload).to be_in_progress

      within ".bops-sidebar" do
        within(".bops-sidebar__task", text: "Site description") do
          expect(page).to have_css("svg[aria-label='In progress']")
        end
      end

      click_button "Save and mark as complete"

      expect(site_description_task.reload).to be_completed

      within ".bops-sidebar" do
        within(".bops-sidebar__task", text: "Site description") do
          expect(page).to have_css("svg[aria-label='Completed']")
        end
      end

      within ".bops-sidebar" do
        click_link "Planning considerations and advice"
      end

      expect(page).to have_current_path("/preapps/#{planning_application.reference}/check-and-assess/assessment-summaries/planning-considerations-and-advice")
      expect(page).to have_selector("h1", text: "Planning considerations and advice")

      within ".bops-sidebar" do
        expect(page).to have_css(".bops-sidebar__task--active", text: "Planning considerations and advice")
      end

      click_button "Save and mark as complete"

      expect(considerations_task.reload).to be_completed

      within ".bops-sidebar" do
        within(".bops-sidebar__task", text: "Planning considerations and advice") do
          expect(page).to have_css("svg[aria-label='Completed']")
        end
      end

      within ".bops-sidebar" do
        click_link "Suggest heads of terms"
      end

      expect(page).to have_current_path("/preapps/#{planning_application.reference}/check-and-assess/assessment-summaries/suggest-heads-of-terms")
      expect(page).to have_selector("h1", text: "Suggest heads of terms")

      within ".bops-sidebar" do
        expect(page).to have_css(".bops-sidebar__task--active", text: "Suggest heads of terms")
      end

      click_button "Save and mark as complete"

      expect(heads_of_terms_task.reload).to be_completed

      within ".bops-sidebar" do
        within(".bops-sidebar__task", text: "Suggest heads of terms") do
          expect(page).to have_css("svg[aria-label='Completed']")
        end
      end

      within ".bops-sidebar" do
        click_link "Summary of advice"
      end

      expect(page).to have_current_path("/preapps/#{planning_application.reference}/check-and-assess/assessment-summaries/summary-of-advice")
      expect(page).to have_selector("h1", text: "Summary of advice")

      within ".bops-sidebar" do
        expect(page).to have_css(".bops-sidebar__task--active", text: "Summary of advice")
      end

      choose "Likely to be supported (recommended based on considerations)"
      fill_in "Enter summary of planning considerations and advice. This should summarise any changes the applicant needs to make before they make an application.", with: "The proposal is acceptable."

      click_button "Save and mark as complete"

      expect(page).to have_content("Summary of advice successfully updated")
      expect(summary_of_advice_task.reload).to be_completed

      within ".bops-sidebar" do
        within(".bops-sidebar__task", text: "Summary of advice") do
          expect(page).to have_css("svg[aria-label='Completed']")
        end
      end

      within ".bops-sidebar" do
        click_link "Choose application type"
      end

      expect(page).to have_current_path("/preapps/#{planning_application.reference}/check-and-assess/complete-assessment/choose-application-type")
      expect(page).to have_selector("h1", text: "Choose application type")

      within ".bops-sidebar" do
        expect(page).to have_css(".bops-sidebar__task--active", text: "Choose application type")
      end

      expect(page).to have_content("What application type would the applicant need to apply for next?")

      select "Prior Approval - Larger extension to a house", from: "What application type would the applicant need to apply for next?"
      click_button "Save and mark as complete"

      expect(page).to have_content("Recommended application type was successfully chosen")
      expect(choose_type_task.reload).to be_completed

      within ".bops-sidebar" do
        within(".bops-sidebar__task", text: "Choose application type") do
          expect(page).to have_css("svg[aria-label='Completed']")
        end
      end

      within ".bops-sidebar" do
        click_link "Check and add requirements"
      end

      expect(page).to have_current_path("/preapps/#{planning_application.reference}/check-and-assess/complete-assessment/check-and-add-requirements")
      expect(page).to have_selector("h1", text: "Check and add requirements")

      within ".bops-sidebar" do
        expect(page).to have_css(".bops-sidebar__task--active", text: "Check and add requirements")
      end

      click_button "Save and mark as complete"

      expect(page).to have_content("Requirements were successfully saved")
      expect(requirements_task.reload).to be_completed

      within ".bops-sidebar" do
        within(".bops-sidebar__task", text: "Check and add requirements") do
          expect(page).to have_css("svg[aria-label='Completed']")
        end
      end

      within ".bops-sidebar" do
        click_link "Review and submit pre-application"
      end

      expect(page).to have_selector("h1", text: "Pre-application report")

      click_button "Confirm and submit recommendation"

      expect(page).to have_content("Pre-application report submitted for review")
      expect(review_submit_task.reload).to be_completed

      [
        check_app_details_task,
        check_consultees_task,
        check_site_history_task,
        site_visit_task,
        meeting_task,
        site_description_task,
        considerations_task,
        heads_of_terms_task,
        summary_of_advice_task,
        choose_type_task,
        requirements_task,
        review_submit_task
      ].each do |task|
        expect(task.reload).to be_completed
      end
    end

    it "shows in progress status when task is partially completed" do
      sign_in(assessor)
      visit "/planning_applications/#{planning_application.reference}/assessment/tasks"

      within ".bops-sidebar" do
        click_link "Site description"
      end

      fill_in "Description of the site", with: "Some text"
      click_button "Save changes"

      expect(page).to have_content("Site description was successfully updated")

      site_description_task = planning_application.case_record.find_task_by_slug_path!("check-and-assess/assessment-summaries/site-description")
      expect(site_description_task.reload).to be_in_progress

      within ".bops-sidebar" do
        within(".bops-sidebar__task", text: "Site description") do
          expect(page).to have_css("svg[aria-label='In progress']")
        end
      end
    end

    it "navigates correctly between all assessment task sections" do
      sign_in(assessor)
      visit "/planning_applications/#{planning_application.reference}/assessment/tasks"

      tasks = [
        {name: "Check application details", path: "check-application/check-application-details"},
        {name: "Check consultees consulted", path: "check-application/check-consultees-consulted"},
        {name: "Check site history", path: "check-application/check-site-history"},
        {name: "Site visit", path: "additional-services/site-visit"},
        {name: "Meeting", path: "additional-services/meeting"},
        {name: "Site description", path: "assessment-summaries/site-description"},
        {name: "Planning considerations and advice", path: "assessment-summaries/planning-considerations-and-advice"},
        {name: "Suggest heads of terms", path: "assessment-summaries/suggest-heads-of-terms"},
        {name: "Summary of advice", path: "assessment-summaries/summary-of-advice"},
        {name: "Choose application type", path: "complete-assessment/choose-application-type"},
        {name: "Check and add requirements", path: "complete-assessment/check-and-add-requirements"}
      ]

      tasks.each do |task|
        within ".bops-sidebar" do
          click_link task[:name]
        end

        expect(page).to have_current_path("/preapps/#{planning_application.reference}/check-and-assess/#{task[:path]}")

        within ".bops-sidebar" do
          expect(page).to have_css(".bops-sidebar__task--active", text: task[:name])
          expect(page).to have_css("a[aria-current='page']", text: task[:name])
        end
      end
    end

    it "hides buttons when application is determined" do
      planning_application.update!(status: "determined", determined_at: Time.current)

      sign_in(assessor)
      visit "/preapps/#{planning_application.reference}/check-and-assess/assessment-summaries/site-description"

      expect(page).not_to have_button("Save and mark as complete")
      expect(page).not_to have_button("Save changes")
    end

    it "maintains sidebar scroll position across navigation", js: true do
      sign_in(assessor)
      visit "/planning_applications/#{planning_application.reference}/assessment/tasks"

      within ".bops-sidebar" do
        click_link "Summary of advice"
      end

      expect(page).to have_css(".bops-sidebar[data-controller='sidebar-scroll']")
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
      visit "/planning_applications/#{planning_application.reference}/assessment/tasks"

      within ".bops-sidebar" do
        click_link "Review and submit pre-application"
      end

      review_submit_task = planning_application.case_record.find_task_by_slug_path!("check-and-assess/complete-assessment/review-and-submit-pre-application")
      expect(review_submit_task).to be_not_started

      click_button "Confirm and submit recommendation"

      expect(page).to have_content("Pre-application report submitted for review")
      expect(review_submit_task.reload).to be_completed

      sign_out(assessor)
      sign_in(reviewer)

      visit "/reports/planning_applications/#{planning_application.reference}?origin=review_and_submit_pre_application"

      within_fieldset "Do you agree with the advice?" do
        choose "No (return the case for assessment)"
        fill_in "Reviewer comment", with: "Needs more detail on considerations"
      end

      click_button "Confirm and submit pre-application report"

      expect(page).to have_content("Pre-application report has been sent back to the case officer for amendments")
      expect(review_submit_task.reload).to be_action_required

      sign_out(reviewer)
      sign_in(assessor)

      visit "/planning_applications/#{planning_application.reference}/assessment/tasks"

      within ".bops-sidebar" do
        within(".bops-sidebar__task", text: "Review and submit pre-application") do
          expect(page).to have_css("svg[aria-label='Action required']")
        end
      end

      within ".bops-sidebar" do
        click_link "Review and submit pre-application"
      end

      fill_in "Assessor comment", with: "Added the requested details"
      click_button "Confirm and submit recommendation"

      expect(page).to have_content("Pre-application report submitted for review")
      expect(review_submit_task.reload).to be_completed

      sign_out(assessor)
      sign_in(reviewer)

      visit "/reports/planning_applications/#{planning_application.reference}?origin=review_and_submit_pre_application"

      within_fieldset "Do you agree with the advice?" do
        choose "Yes"
      end

      click_button "Confirm and submit pre-application report"

      expect(page).to have_content("Pre-application report has been sent to the applicant")
      expect(review_submit_task.reload).to be_completed
    end
  end

  describe "site visit recording" do
    it "allows adding a site visit with date and comments" do
      sign_in(assessor)
      visit "/planning_applications/#{planning_application.reference}/assessment/tasks"

      within ".bops-sidebar" do
        click_link "Site visit"
      end

      site_visit_task = planning_application.case_record.find_task_by_slug_path!("check-and-assess/additional-services/site-visit")
      expect(site_visit_task).to be_not_started

      expect(page).to have_content("No site visits have been recorded yet")

      within "#new-site-visit-form" do
        click_button "Add site visit"
      end

      yesterday = Date.yesterday
      within "#new-site-visit-form" do
        fill_in "Day", with: yesterday.day
        fill_in "Month", with: yesterday.month
        fill_in "Year", with: yesterday.year
        fill_in "Comment", with: "Inspected front and rear of property"
        click_button "Add site visit"
      end

      click_button "Save changes"

      expect(site_visit_task.reload).to be_in_progress

      within ".bops-sidebar" do
        within(".bops-sidebar__task", text: "Site visit") do
          expect(page).to have_css("svg[aria-label='In progress']")
        end
      end

      expect(page).not_to have_content("No site visits have been recorded yet")

      within("#site-visit-history") do
        expect(page).to have_content("Inspected front and rear of property")
      end
    end
  end

  describe "check application details with issues" do
    it "shows request links when selecting No for checks" do
      sign_in(assessor)
      visit "/planning_applications/#{planning_application.reference}/assessment/tasks"

      within ".bops-sidebar" do
        click_link "Check application details"
      end

      within_fieldset("Does the description match the development or use in the plans?") { choose "No" }

      expect(page).to have_link("Request a change to the description")

      within_fieldset("Are the plans consistent with each other?") { choose "No" }

      expect(page).to have_link("Request a new document")
    end
  end
end
