# frozen_string_literal: true

RSpec.shared_examples "other validation requests task" do |application_type|
  let(:local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user, local_authority:, name: "Alice Smith") }
  let(:task) { planning_application.case_record.find_task_by_slug_path!("check-and-validate/other-validation-issues/other-validation-requests") }

  before do
    sign_in(user)
    visit "/planning_applications/#{planning_application.reference}/validation/tasks"
  end

  it "shows the task in the sidebar with not started status" do
    expect(task.status).to eq("not_started")

    within :sidebar do
      expect(page).to have_link("Other validation requests")
    end
  end

  it "navigates to the task from the sidebar" do
    within :sidebar do
      click_link "Other validation requests"
    end

    expect(page).to have_content("Other validation requests")
  end

  context "when there are no validation requests" do
    it "displays a message indicating no requests" do
      within :sidebar do
        click_link "Other validation requests"
      end

      expect(page).to have_content("No other validation requests have been added")
    end

    it "shows a link to add a validation request" do
      within :sidebar do
        click_link "Other validation requests"
      end

      expect(page).to have_link("Add other validation request")
    end

    it "can add a new validation request and returns to the task" do
      within :sidebar do
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

    it "can complete the task without validation requests" do
      within :sidebar do
        click_link "Other validation requests"
      end

      click_button "Save and mark as complete"

      expect(task.reload).to be_completed
    end
  end

  context "when there is an existing validation request" do
    let!(:validation_request) do
      create(:other_change_validation_request,
        :pending,
        planning_application:,
        reason: "Application is incomplete",
        suggestion: "Please complete all sections",
        user:)
    end

    it "displays the validation request in the table" do
      within :sidebar do
        click_link "Other validation requests"
      end

      expect(page).to have_content("Application is incomplete")
      expect(page).to have_content("Please complete all sections")
      expect(page).to have_content("Alice Smith")
    end

    it "can view a validation request" do
      within :sidebar do
        click_link "Other validation requests"
      end

      click_link "Application is incomplete"

      expect(page).to have_content("View other request")
      expect(page).to have_content("Application is incomplete")
    end

    it "can edit a validation request and returns to the task" do
      within :sidebar do
        click_link "Other validation requests"
      end

      click_link "Application is incomplete"

      expect(page).to have_content("View other request")

      click_link "Edit request"

      expect(page).to have_content("Update other validation request")

      fill_in "Tell the applicant another reason why the application is invalid", with: "Updated reason"
      click_button "Update request"

      expect(page).to have_current_path(%r{/check-and-validate/other-validation-issues/other-validation-requests})
      expect(page).to have_content("Updated reason")
    end

    it "can delete a validation request and returns to the task", js: true do
      within :sidebar do
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

  context "when application is invalidated with an open validation request" do
    let!(:validation_request) do
      create(:other_change_validation_request,
        :open,
        planning_application:,
        reason: "Application is incomplete",
        suggestion: "Please complete all sections",
        user:)
    end

    before do
      planning_application.update!(status: "invalidated")
    end

    it "can cancel a validation request and returns to the task" do
      within :sidebar do
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
end
