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

  let(:reference) { planning_application.reference }

  before do
    sign_in(user)
  end

  describe "end-to-end validation workflow" do
    it "completes all validation tasks in sequence with correct status transitions and icons" do
      visit "/planning_applications/#{reference}/validation"

      expect(page).to have_selector(:sidebar)
      expect(page).to have_content("Validation")

      within :sidebar do
        expect(page).to have_content("Check, tag, and confirm documents")
        expect(page).to have_content("Check application details")
        expect(page).to have_content("Other validation issues")
        expect(page).to have_content("Review")
      end

      expect(validation_tasks).to all(be_not_started)

      within :sidebar do
        expect(page).to have_css("svg[aria-label='Not started']", minimum: 7)
      end

      within :sidebar do
        click_link "Review documents"
      end

      expect(page).to have_current_path("/preapps/#{reference}/check-and-validate/check-tag-and-confirm-documents/review-documents")
      expect(page).to have_selector("h1", text: "Review documents")
      expect(page).to have_selector(:active_sidebar_task, "Review documents")

      expect(page).to have_content("There are no active documents")

      click_button "Save and mark as complete"

      expect(page).to have_content("Successfully updated document review")
      expect(task("Review documents").reload).to be_completed
      expect(page).to have_selector(:completed_sidebar_task, "Review documents")

      within :sidebar do
        click_link "Check red line boundary"
      end

      expect(page).to have_current_path("/preapps/#{reference}/check-and-validate/check-application-details/check-red-line-boundary")
      expect(page).to have_content("Check the digital red line boundary")
      expect(page).to have_selector(:active_sidebar_task, "Check red line boundary")

      expect(page).to have_field("Yes")
      expect(page).to have_field("No")

      choose "Yes"
      click_button "Save and mark as complete"

      expect(page).to have_content("Red line boundary check was successfully saved")
      expect(task("Check red line boundary").reload).to be_completed
      expect(planning_application.reload.valid_red_line_boundary).to be true
      expect(page).to have_selector(:completed_sidebar_task, "Check red line boundary")

      within :sidebar do
        click_link "Check constraints"
      end

      expect(page).to have_current_path("/preapps/#{reference}/check-and-validate/check-application-details/check-constraints")
      expect(page).to have_content("Check constraints")
      expect(page).to have_selector(:active_sidebar_task, "Check constraints")

      within(".identified-constraints-table") do
        expect(page).to have_text("Conservation area")
        expect(page).to have_text("Listed building outline")
      end

      click_button "Save and mark as complete"

      expect(page).to have_content("Constraints were successfully marked as reviewed")
      expect(task("Check constraints").reload).to be_completed
      expect(page).to have_selector(:completed_sidebar_task, "Check constraints")

      within :sidebar do
        click_link "Check description"
      end

      expect(page).to have_current_path("/preapps/#{reference}/check-and-validate/check-application-details/check-description")
      expect(page).to have_selector("h1", text: "Check description")
      expect(page).to have_selector(:active_sidebar_task, "Check description")

      expect(page).to have_content("Does the description match the development or use in the plans?")

      choose "Yes"
      click_button "Save and mark as complete"

      expect(page).to have_content("Description check was successfully saved")
      expect(task("Check description").reload).to be_completed
      expect(planning_application.reload.valid_description).to be true
      expect(page).to have_selector(:completed_sidebar_task, "Check description")

      within :sidebar do
        click_link "Check fee"
      end

      expect(page).to have_current_path("/preapps/#{reference}/check-and-validate/check-application-details/check-fee")
      expect(page).to have_content("Check the application fee")
      expect(page).to have_selector(:active_sidebar_task, "Check fee")

      expect(page).to have_content("Payment information")
      expect(page).to have_content("Fee calculation")
      expect(page).to have_content("Householder")
      expect(page).to have_content("£100")

      choose "Yes"
      click_button "Save and mark as complete"

      expect(page).to have_content("Fee check was successfully saved")
      expect(task("Check fee").reload).to be_completed
      expect(planning_application.reload.valid_fee).to be true
      expect(page).to have_selector(:completed_sidebar_task, "Check fee")

      within :sidebar do
        click_link "Other validation requests"
      end

      expect(page).to have_current_path("/preapps/#{reference}/check-and-validate/other-validation-issues/other-validation-requests")
      expect(page).to have_selector("h1", text: "Other validation requests")
      expect(page).to have_selector(:active_sidebar_task, "Other validation requests")

      expect(page).to have_content("No other validation requests have been added")

      click_button "Save and mark as complete"

      expect(page).to have_content("Other validation requests was successfully saved")
      expect(task("Other validation requests").reload).to be_completed
      expect(page).to have_selector(:completed_sidebar_task, "Other validation requests")

      within :sidebar do
        click_link "Review validation requests"
      end

      expect(page).to have_current_path("/preapps/#{reference}/check-and-validate/review/review-validation-requests")
      expect(page).to have_selector("h1", text: "Review validation requests")
      expect(page).to have_selector(:active_sidebar_task, "Review validation requests")

      expect(page).to have_content("There are no active validation requests")

      within :sidebar do
        click_link "Send validation decision"
      end

      expect(page).to have_current_path("/preapps/#{reference}/check-and-validate/review/send-validation-decision")
      expect(page).to have_selector("h1", text: "Send validation decision")
      expect(page).to have_selector(:active_sidebar_task, "Send validation decision")

      expect(page).to have_content("The application has not been marked as valid or invalid yet")
      expect(page).to have_button("Mark the application as valid")

      click_button "Mark the application as valid"

      expect(page).to have_content("An email notification has been sent to the applicant. The application is now ready for consultation and assessment")

      click_link "Check and validate"
      within :sidebar do
        click_link "Send validation decision"
      end

      expect(page).to have_content("The application is marked as valid")
      expect(task("Send validation decision").reload).to be_completed
      expect(planning_application.reload).to be_valid
      expect(page).to have_selector(:completed_sidebar_task, "Send validation decision")
    end

    it "shows in progress status when is opened for editing after completion" do
      visit "/planning_applications/#{reference}/validation"

      within :sidebar do
        click_link "Check constraints"
      end

      click_button "Save and mark as complete"

      expect(page).to have_content("Constraints were successfully marked as reviewed")
      expect(task("Check constraints").reload).to be_completed
      expect(page).to have_selector(:completed_sidebar_task, "Check constraints")

      expect(page).to have_button("Edit")
      click_button "Edit"
      expect(page).to have_selector(:in_progress_sidebar_task, "Check constraints")
    end

    it "handles validation request flow with status transitions" do
      visit "/planning_applications/#{reference}/validation"

      within :sidebar do
        click_link "Check description"
      end

      choose "No"
      click_button "Save and mark as complete"

      expect(page).to have_current_path("/planning_applications/#{reference}/validation/validation_requests/new?type=description_change")

      expect(task("Check description").reload).to be_in_progress
      expect(planning_application.reload.valid_description).to be false

      visit "/planning_applications/#{reference}/validation"

      expect(page).to have_selector(:in_progress_sidebar_task, "Check description")
    end

    it "navigates correctly between all validation task sections" do
      visit "/planning_applications/#{reference}/validation"

      sections = [
        {name: "Review documents", path: "check-tag-and-confirm-documents/review-documents"},
        {name: "Check red line boundary", path: "check-application-details/check-red-line-boundary"},
        {name: "Check constraints", path: "check-application-details/check-constraints"},
        {name: "Check description", path: "check-application-details/check-description"},
        {name: "Check fee", path: "check-application-details/check-fee"},
        {name: "Other validation requests", path: "other-validation-issues/other-validation-requests"},
        {name: "Review validation requests", path: "review/review-validation-requests"},
        {name: "Send validation decision", path: "review/send-validation-decision"}
      ]

      sections.each do |section|
        within :sidebar do
          click_link section[:name]
        end

        expect(page).to have_current_path("/preapps/#{reference}/check-and-validate/#{section[:path]}")
        expect(page).to have_selector(:active_sidebar_task, section[:name])
      end
    end

    it "hides buttons when application is determined" do
      planning_application.update!(status: "determined", determined_at: Time.current)

      visit "/preapps/#{reference}/check-and-validate/check-application-details/check-description"

      expect(page).not_to have_button("Save and mark as complete")
      expect(page).not_to have_button("Save changes")
    end
  end
end
