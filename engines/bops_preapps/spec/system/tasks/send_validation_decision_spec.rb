# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Send validation decision task", type: :system, capybara: true do
  let(:local_authority) { create(:local_authority, :default) }
  let(:planning_application) { create(:planning_application, :pre_application, :not_started, local_authority:) }
  let(:user) { create(:user, local_authority:) }
  let(:task) { planning_application.case_record.find_task_by_slug_path!("check-and-validate/review/send-validation-decision") }

  before do
    Rails.application.load_seed
    sign_in(user)
    visit "/planning_applications/#{planning_application.reference}/validation/tasks"
  end

  it "allows the application to be made valid" do
    within ".bops-sidebar" do
      click_link "Send validation decision"
    end

    expect(task).to be_not_started
    expect(page).to have_current_path("/preapps/#{planning_application.reference}/check-and-validate/review/send-validation-decision")
    expect(page).to have_selector("h1", text: "Send validation decision")
    expect(page).to have_content("The application has not been marked as valid or invalid yet.")

    click_button("Mark the application as valid")

    expect(page).to have_content("The application is marked as valid and cannot be marked as invalid.")
    expect(task.reload).to be_completed
    expect(planning_application.reload).to be_valid
  end

  context "when there are outstanding validation requests" do
    it "allows the application to be marked as invalid with outstanding validation requests" do
      create(:other_change_validation_request, planning_application: planning_application, state: "pending",
        created_at: 7.days.ago)

      within ".bops-sidebar" do
        click_link "Send validation decision"
      end

      expect(task).to be_not_started
      expect(page).to have_current_path("/preapps/#{planning_application.reference}/check-and-validate/review/send-validation-decision")
      expect(page).to have_selector("h1", text: "Send validation decision")
      expect(page).to have_content("You have marked items as invalid, so you cannot validate this application.")

      click_button("Mark the application as invalid")

      expect(page).to have_content("The application is marked as invalid.")
      expect(task.reload).to be_completed
      expect(planning_application.reload.status).to eq("invalidated")

      click_link "View existing requests"
      expect(page).to have_current_path("/planning_applications/#{planning_application.reference}/validation/validation_requests")
      expect(page).to have_content("Review validation requests")

      click_link "View and update"
      click_link "Cancel request"
      fill_in "Explain to the applicant why this request is being cancelled", with: "No longer needed"
      click_button "Confirm cancellation"
      expect(page).to have_content("Change request successfully cancelled.")

      within ".bops-sidebar" do
        click_link "Send validation decision"
      end

      expect(page).to have_selector("h1", text: "Send validation decision")
      expect(page).to have_content("Once the application has been checked and all validation requests resolved, mark the application as valid.")

      click_button("Mark the application as valid")
      expect(page).to have_content("The application is marked as valid and cannot be marked as invalid.")
      expect(task.reload).to be_completed
      expect(planning_application.reload).to be_valid
    end
  end
end
