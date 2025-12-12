# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Check description task", type: :system, capybara: true do
  let(:local_authority) { create(:local_authority, :default) }
  let(:planning_application) { create(:planning_application, :pre_application, :not_started, local_authority:) }
  let(:user) { create(:user, local_authority:) }
  let(:task) { planning_application.case_record.find_task_by_slug_path!("check-and-validate/check-application-details/check-description") }

  before do
    sign_in(user)
    visit "/planning_applications/#{planning_application.reference}/validation/tasks"
  end

  it "shows the task in the sidebar with not started status" do
    expect(task.status).to eq("not_started")

    within ".bops-sidebar" do
      expect(page).to have_link("Check description")
    end
  end

  it "navigates to the task from the sidebar" do
    within ".bops-sidebar" do
      click_link "Check description"
    end

    expect(page).to have_current_path("/preapps/#{planning_application.reference}/check-and-validate/check-application-details/check-description")
    expect(page).to have_selector("h1", text: "Check description")
  end

  it "displays the form to check the description" do
    within ".bops-sidebar" do
      click_link "Check description"
    end

    expect(page).to have_content("Does the description match the development or use in the plans?")
    expect(page).to have_field("Yes")
    expect(page).to have_field("No")
    expect(page).to have_button("Save and mark as complete")
  end

  it "marks task as complete when selecting Yes" do
    expect(task).to be_not_started

    within ".bops-sidebar" do
      click_link "Check description"
    end

    choose "Yes"
    click_button "Save and mark as complete"

    expect(page).to have_content("Description check was successfully saved")
    expect(task.reload).to be_completed
    expect(planning_application.reload.valid_description).to be true
  end

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

    expect(task.reload).to be_completed

    expect(planning_application.reload.description).to eq("This is an updated description.")
    expect(page).to have_current_path(
        "/preapps/#{planning_application.reference}/check-and-validate/check-application-details/check-description"
      )
  end

  it "shows error when no selection is made" do
    within ".bops-sidebar" do
      click_link "Check description"
    end

    click_button "Save and mark as complete"

    expect(page).to have_content("Select whether the description is correct")
    expect(task.reload).to be_not_started
  end

  it "hides save button when application is determined" do
    planning_application.update!(status: "determined", determined_at: Time.current)

    within ".bops-sidebar" do
      click_link "Check description"
    end

    expect(page).not_to have_button("Save and mark as complete")
  end
end
