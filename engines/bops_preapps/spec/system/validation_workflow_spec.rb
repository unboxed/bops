# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Pre-application validation workflow", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:api_user) { create(:api_user, :planx, local_authority:) }
  let(:user) { create(:user, local_authority:, name: "Alice Smith") }

  let(:boundary_geojson) do
    {
      type: "Feature",
      properties: {},
      geometry: {
        type: "Polygon",
        coordinates: [[[-0.054597, 51.537331], [-0.054588, 51.537287], [-0.054453, 51.537313], [-0.054597, 51.537331]]]
      }
    }
  end

  let(:proposal_details) do
    [{"question" => "Planning Pre-Application Advice Services", "responses" => [{"value" => "Householder (£100)"}], "metadata" => {}}]
  end

  let(:planning_application) do
    create(:planning_application, :pre_application, :not_started, :with_constraints,
      local_authority:,
      api_user:,
      boundary_geojson:,
      proposal_details:)
  end

  before do
    sign_in(user)
  end

  describe "end-to-end validation workflow" do
    it "completes all validation tasks in sequence with correct status transitions and icons" do
      visit "/planning_applications/#{planning_application.reference}/validation/tasks"

      expect(page).to have_css(".bops-sidebar")
      expect(page).to have_content("Validation")

      within ".bops-sidebar" do
        expect(page).to have_content("Check, tag, and confirm documents")
        expect(page).to have_content("Check application details")
        expect(page).to have_content("Other validation issues")
        expect(page).to have_content("Review")
      end

      review_documents_task = planning_application.case_record.find_task_by_slug_path!("check-and-validate/check-tag-and-confirm-documents/review-documents")
      check_red_line_task = planning_application.case_record.find_task_by_slug_path!("check-and-validate/check-application-details/check-red-line-boundary")
      check_constraints_task = planning_application.case_record.find_task_by_slug_path!("check-and-validate/check-application-details/check-constraints")
      check_description_task = planning_application.case_record.find_task_by_slug_path!("check-and-validate/check-application-details/check-description")
      add_reporting_task = planning_application.case_record.find_task_by_slug_path!("check-and-validate/check-application-details/add-reporting-details")
      check_fee_task = planning_application.case_record.find_task_by_slug_path!("check-and-validate/check-application-details/check-fee")
      other_requests_task = planning_application.case_record.find_task_by_slug_path!("check-and-validate/other-validation-issues/other-validation-requests")
      review_requests_task = planning_application.case_record.find_task_by_slug_path!("check-and-validate/review/review-validation-requests")
      send_decision_task = planning_application.case_record.find_task_by_slug_path!("check-and-validate/review/send-validation-decision")

      expect(review_documents_task).to be_not_started
      expect(check_red_line_task).to be_not_started
      expect(check_constraints_task).to be_not_started
      expect(check_description_task).to be_not_started
      expect(add_reporting_task).to be_not_started
      expect(check_fee_task).to be_not_started
      expect(other_requests_task).to be_not_started
      expect(review_requests_task).to be_not_started
      expect(send_decision_task).to be_not_started

      within ".bops-sidebar" do
        expect(page).to have_css("svg[aria-label='Not started']", minimum: 7)
      end

      within ".bops-sidebar" do
        click_link "Review documents"
      end

      expect(page).to have_current_path("/preapps/#{planning_application.reference}/check-and-validate/check-tag-and-confirm-documents/review-documents")
      expect(page).to have_selector("h1", text: "Review documents")

      within ".bops-sidebar" do
        expect(page).to have_css(".bops-sidebar__task--active", text: "Review documents")
        expect(page).to have_css("a[aria-current='page']", text: "Review documents")
      end

      expect(page).to have_content("There are no active documents")

      click_button "Save and mark as complete"

      expect(page).to have_content("Successfully updated document review")
      expect(review_documents_task.reload).to be_completed

      within ".bops-sidebar" do
        within(".bops-sidebar__task", text: "Review documents") do
          expect(page).to have_css("svg[aria-label='Completed']")
        end
      end

      within ".bops-sidebar" do
        click_link "Check red line boundary"
      end

      expect(page).to have_current_path("/preapps/#{planning_application.reference}/check-and-validate/check-application-details/check-red-line-boundary")
      expect(page).to have_content("Check the digital red line boundary")

      within ".bops-sidebar" do
        expect(page).to have_css(".bops-sidebar__task--active", text: "Check red line boundary")
      end

      expect(page).to have_field("Yes")
      expect(page).to have_field("No")

      choose "Yes"
      click_button "Save and mark as complete"

      expect(page).to have_content("Red line boundary check was successfully saved")
      expect(check_red_line_task.reload).to be_completed
      expect(planning_application.reload.valid_red_line_boundary).to be true

      within ".bops-sidebar" do
        within(".bops-sidebar__task", text: "Check red line boundary") do
          expect(page).to have_css("svg[aria-label='Completed']")
        end
      end

      within ".bops-sidebar" do
        click_link "Check constraints"
      end

      expect(page).to have_current_path("/preapps/#{planning_application.reference}/check-and-validate/check-application-details/check-constraints")
      expect(page).to have_content("Check constraints")

      within ".bops-sidebar" do
        expect(page).to have_css(".bops-sidebar__task--active", text: "Check constraints")
      end

      within(".identified-constraints-table") do
        expect(page).to have_text("Conservation area")
        expect(page).to have_text("Listed building outline")
      end

      click_button "Save and mark as complete"

      expect(page).to have_content("Constraints were successfully marked as reviewed")
      expect(check_constraints_task.reload).to be_completed

      within ".bops-sidebar" do
        within(".bops-sidebar__task", text: "Check constraints") do
          expect(page).to have_css("svg[aria-label='Completed']")
        end
      end

      within ".bops-sidebar" do
        click_link "Check description"
      end

      expect(page).to have_current_path("/preapps/#{planning_application.reference}/check-and-validate/check-application-details/check-description")
      expect(page).to have_selector("h1", text: "Check description")

      within ".bops-sidebar" do
        expect(page).to have_css(".bops-sidebar__task--active", text: "Check description")
      end

      expect(page).to have_content("Does the description match the development or use in the plans?")

      choose "Yes"
      click_button "Save and mark as complete"

      expect(page).to have_content("Description check was successfully saved")
      expect(check_description_task.reload).to be_completed
      expect(planning_application.reload.valid_description).to be true

      within ".bops-sidebar" do
        within(".bops-sidebar__task", text: "Check description") do
          expect(page).to have_css("svg[aria-label='Completed']")
        end
      end

      within ".bops-sidebar" do
        click_link "Add reporting details"
      end

      expect(page).to have_current_path("/preapps/#{planning_application.reference}/check-and-validate/check-application-details/add-reporting-details")
      expect(page).to have_selector("h1", text: "Add reporting details")

      within ".bops-sidebar" do
        expect(page).to have_css(".bops-sidebar__task--active", text: "Add reporting details")
      end

      expect(page).to have_content("Is the local planning authority the owner of this land?")

      page.first(:radio_button, "No").choose

      click_button "Save and mark as complete"

      expect(page).to have_content("Reporting details were successfully saved")
      expect(add_reporting_task.reload).to be_completed

      within ".bops-sidebar" do
        within(".bops-sidebar__task", text: "Add reporting details") do
          expect(page).to have_css("svg[aria-label='Completed']")
        end
      end

      within ".bops-sidebar" do
        click_link "Check fee"
      end

      expect(page).to have_current_path("/preapps/#{planning_application.reference}/check-and-validate/check-application-details/check-fee")
      expect(page).to have_content("Check the application fee")

      within ".bops-sidebar" do
        expect(page).to have_css(".bops-sidebar__task--active", text: "Check fee")
      end

      expect(page).to have_content("Payment information")
      expect(page).to have_content("Fee calculation")
      expect(page).to have_content("Householder")
      expect(page).to have_content("£100")

      choose "Yes"
      click_button "Save and mark as complete"

      expect(page).to have_content("Fee check was successfully saved")
      expect(check_fee_task.reload).to be_completed
      expect(planning_application.reload.valid_fee).to be true

      within ".bops-sidebar" do
        within(".bops-sidebar__task", text: "Check fee") do
          expect(page).to have_css("svg[aria-label='Completed']")
        end
      end

      within ".bops-sidebar" do
        click_link "Other validation requests"
      end

      expect(page).to have_current_path("/preapps/#{planning_application.reference}/check-and-validate/other-validation-issues/other-validation-requests")
      expect(page).to have_selector("h1", text: "Other validation requests")

      within ".bops-sidebar" do
        expect(page).to have_css(".bops-sidebar__task--active", text: "Other validation requests")
      end

      expect(page).to have_content("No other validation requests have been added")

      click_button "Save and mark as complete"

      expect(page).to have_content("Other validation requests was successfully saved")
      expect(other_requests_task.reload).to be_completed

      within ".bops-sidebar" do
        within(".bops-sidebar__task", text: "Other validation requests") do
          expect(page).to have_css("svg[aria-label='Completed']")
        end
      end

      within ".bops-sidebar" do
        click_link "Review validation requests"
      end

      expect(page).to have_current_path("/preapps/#{planning_application.reference}/check-and-validate/review/review-validation-requests")
      expect(page).to have_selector("h1", text: "Review validation requests")

      within ".bops-sidebar" do
        expect(page).to have_css(".bops-sidebar__task--active", text: "Review validation requests")
      end

      expect(page).to have_content("There are no active validation requests")

      within ".bops-sidebar" do
        click_link "Send validation decision"
      end

      expect(page).to have_current_path("/preapps/#{planning_application.reference}/check-and-validate/review/send-validation-decision")
      expect(page).to have_selector("h1", text: "Send validation decision")

      within ".bops-sidebar" do
        expect(page).to have_css(".bops-sidebar__task--active", text: "Send validation decision")
      end

      expect(page).to have_content("The application has not been marked as valid or invalid yet")
      expect(page).to have_button("Mark the application as valid")

      click_button "Mark the application as valid"

      expect(page).to have_content("The application is marked as valid")
      expect(send_decision_task.reload).to be_completed
      expect(planning_application.reload).to be_valid

      within ".bops-sidebar" do
        within(".bops-sidebar__task", text: "Send validation decision") do
          expect(page).to have_css("svg[aria-label='Completed']")
        end
      end

      [
        review_documents_task,
        check_red_line_task,
        check_constraints_task,
        check_description_task,
        add_reporting_task,
        check_fee_task,
        other_requests_task,
        send_decision_task
      ].each do |task|
        expect(task.reload).to be_completed
      end
    end

    it "shows in progress status when task is partially completed" do
      visit "/planning_applications/#{planning_application.reference}/validation/tasks"

      within ".bops-sidebar" do
        click_link "Check constraints"
      end

      click_button "Save changes"

      expect(page).to have_content("Constraints were successfully marked as reviewed")

      check_constraints_task = planning_application.case_record.find_task_by_slug_path!("check-and-validate/check-application-details/check-constraints")
      expect(check_constraints_task.reload).to be_in_progress

      within ".bops-sidebar" do
        within(".bops-sidebar__task", text: "Check constraints") do
          expect(page).to have_css("svg[aria-label='In progress']")
        end
      end
    end

    it "handles validation request flow with status transitions" do
      visit "/planning_applications/#{planning_application.reference}/validation/tasks"

      within ".bops-sidebar" do
        click_link "Check description"
      end

      choose "No"
      click_button "Save and mark as complete"

      expect(page).to have_current_path("/planning_applications/#{planning_application.reference}/validation/validation_requests/new?type=description_change")

      check_description_task = planning_application.case_record.find_task_by_slug_path!("check-and-validate/check-application-details/check-description")
      expect(check_description_task.reload).to be_in_progress
      expect(planning_application.reload.valid_description).to be false

      visit "/planning_applications/#{planning_application.reference}/validation/tasks"

      within ".bops-sidebar" do
        within(".bops-sidebar__task", text: "Check description") do
          expect(page).to have_css("svg[aria-label='In progress']")
        end
      end
    end

    it "navigates correctly between all validation task sections" do
      visit "/planning_applications/#{planning_application.reference}/validation/tasks"

      sections = [
        {name: "Review documents", path: "check-tag-and-confirm-documents/review-documents"},
        {name: "Check red line boundary", path: "check-application-details/check-red-line-boundary"},
        {name: "Check constraints", path: "check-application-details/check-constraints"},
        {name: "Check description", path: "check-application-details/check-description"},
        {name: "Add reporting details", path: "check-application-details/add-reporting-details"},
        {name: "Check fee", path: "check-application-details/check-fee"},
        {name: "Other validation requests", path: "other-validation-issues/other-validation-requests"},
        {name: "Review validation requests", path: "review/review-validation-requests"},
        {name: "Send validation decision", path: "review/send-validation-decision"}
      ]

      sections.each do |section|
        within ".bops-sidebar" do
          click_link section[:name]
        end

        expect(page).to have_current_path("/preapps/#{planning_application.reference}/check-and-validate/#{section[:path]}")

        within ".bops-sidebar" do
          expect(page).to have_css(".bops-sidebar__task--active", text: section[:name])
          expect(page).to have_css("a[aria-current='page']", text: section[:name])
        end
      end
    end

    it "hides buttons when application is determined" do
      planning_application.update!(status: "determined", determined_at: Time.current)

      visit "/preapps/#{planning_application.reference}/check-and-validate/check-application-details/check-description"

      expect(page).not_to have_button("Save and mark as complete")
      expect(page).not_to have_button("Save changes")
    end

    it "maintains sidebar scroll position across navigation", js: true do
      visit "/planning_applications/#{planning_application.reference}/validation/tasks"

      within ".bops-sidebar" do
        click_link "Send validation decision"
      end

      expect(page).to have_css(".bops-sidebar[data-controller='sidebar-scroll']")
    end
  end
end
