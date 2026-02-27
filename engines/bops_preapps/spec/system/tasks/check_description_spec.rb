# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Check description task", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:planning_application) { create(:planning_application, :pre_application, :not_started, local_authority:) }
  let(:user) { create(:user, local_authority:) }
  let(:task) {
    planning_application.case_record.find_task_by_slug_path!("check-and-validate/check-application-details/check-description")
  }

  before do
    sign_in(user)
    visit "/planning_applications/#{planning_application.reference}/validation/tasks"
  end

  it_behaves_like "check description task", :pre_application

  it "redirects to validation request with sidebar when selecting No" do
    expect(task).to be_not_started

    within ".bops-sidebar" do
      click_link "Check description"
    end

    choose "No"
    click_button "Save and mark as complete"

    expect(page).to have_current_path(
      "/planning_applications/#{planning_application.reference}/validation/validation_requests/new?type=description_change"
    )
    expect(task.reload).to be_in_progress
    expect(planning_application.reload.valid_description).to be false

    within ".bops-sidebar" do
      expect(page).to have_content("Validation")
    end
  end

  it "completes full validation request flow" do
    expect(task).to be_not_started

    within ".bops-sidebar" do
      click_link "Check description"
    end

    choose "No"
    click_button "Save and mark as complete"

    expect(page).to have_content("Description check was successfully saved")
    expect(page).to have_content("Description change")

    fill_in "Enter an amended description", with: "This is an updated description."
    click_button "Save and mark as complete"

    expect(page).to have_content "Description updated."
    expect(task.reload).to be_completed

    expect(planning_application.reload.description).to eq("This is an updated description.")
    expect(page).to have_current_path(
        "/preapps/#{planning_application.reference}/check-and-validate/check-application-details/check-description"
      )
  end
end
