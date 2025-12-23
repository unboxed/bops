# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Other validation requests task", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:planning_application) { create(:planning_application, :pre_application, :not_started, local_authority:) }
  let(:task) { planning_application.case_record.find_task_by_slug_path!("check-and-validate/other-validation-issues/other-validation-requests") }

  let(:user) { create(:user, local_authority:, name: "Alice Smith") }

  before do
    Rails.application.load_seed
    sign_in(user)
    visit "/planning_applications/#{planning_application.reference}/validation/tasks"
  end

  context "when there are no validation requests" do
    it "displays a message indicating no requests" do
      within ".bops-sidebar" do
        click_link "Other validation requests"
      end

      expect(page).to have_content("No other validation requests have been added")
    end

    it "can add a new validation request and returns to the task" do
      within ".bops-sidebar" do
        click_link "Other validation requests"
      end

      click_link "Add other validation request"

      expect(page).to have_content("Request other validation change")

      fill_in "Tell the applicant another reason why the application is invalid", with: "Missing information"
      fill_in "Explain to the applicant how the application can be made valid", with: "Please provide the missing details"

      click_button "Save request"

      expect(page).to have_current_path(%r{/check-and-validate/other-validation-issues/other-validation-requests})
      expect(page).to have_content("Missing information")
    end
  end

  context "when there is an existing validation request" do
    let!(:validation_request) do
      create(:other_change_validation_request,
        :pending,
        planning_application:,
        reason: "Application is incomplete",
        suggestion: "Please complete all sections")
    end

    it "displays the validation request in the table" do
      within ".bops-sidebar" do
        click_link "Other validation requests"
      end

      expect(page).to have_content("Application is incomplete")
    end

    it "can view and edit a validation request and returns to the task" do
      within ".bops-sidebar" do
        click_link "Other validation requests"
      end

      click_link "Application is incomplete"

      expect(page).to have_content("View other request")
      expect(page).to have_content("Application is incomplete")

      click_link "Edit request"

      expect(page).to have_content("Update other validation request")

      fill_in "Tell the applicant another reason why the application is invalid", with: "Updated reason"
      click_button "Update request"

      expect(page).to have_current_path(%r{/check-and-validate/other-validation-issues/other-validation-requests})
      expect(page).to have_content("Updated reason")
    end

    it "can delete a validation request and returns to the task", js: true do
      within ".bops-sidebar" do
        click_link "Other validation requests"
      end

      click_link "Application is incomplete"

      accept_confirm do
        click_link "Delete request"
      end

      expect(page).to have_current_path(%r{/check-and-validate/other-validation-issues/other-validation-requests})
      expect(page).to have_content("No other validation requests have been added")
    end
  end

  context "when application is invalidated" do
    let!(:validation_request) do
      create(:other_change_validation_request,
        :open,
        planning_application:,
        reason: "Application is incomplete",
        suggestion: "Please complete all sections")
    end

    before do
      planning_application.update!(status: "invalidated")
    end

    it "can cancel a validation request and returns to the task" do
      within ".bops-sidebar" do
        click_link "Other validation requests"
      end

      click_link "Application is incomplete"

      expect(page).to have_link("Cancel request")

      click_link "Cancel request"

      expect(page).to have_content("Cancel validation request")

      fill_in "Explain to the applicant why this request is being cancelled", with: "No longer needed"
      click_button "Confirm cancellation"

      expect(page).to have_current_path(%r{/check-and-validate/other-validation-issues/other-validation-requests})
    end
  end

  it "can complete the task" do
    within ".bops-sidebar" do
      click_link "Other validation requests"
    end

    click_button "Save and mark as complete"

    expect(task.reload).to be_completed
  end
end
