# frozen_string_literal: true

RSpec.shared_examples "check description task" do |application_type|
  let(:local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user, local_authority:) }
  let(:task) { planning_application.case_record.find_task_by_slug_path!("check-and-validate/check-application-details/check-description") }

  let(:url_prefix) { (application_type == :pre_application) ? "preapps" : "planning_applications" }

  before do
    sign_in(user)
    visit "/planning_applications/#{planning_application.reference}/validation"
  end

  it "shows the task in the sidebar with not started status" do
    expect(task.status).to eq("not_started")

    within :sidebar do
      expect(page).to have_link("Check description")
    end
  end

  it "navigates to the task from the sidebar" do
    within :sidebar do
      click_link "Check description"
    end

    expect(page).to have_current_path("/#{url_prefix}/#{planning_application.reference}/check-and-validate/check-application-details/check-description")
    expect(page).to have_selector("h1", text: "Check description")
  end

  it "displays the form to check the description" do
    within :sidebar do
      click_link "Check description"
    end

    expect(page).to have_content("Does the description match the development or use in the plans?")
    expect(page).to have_field("Yes")
    expect(page).to have_field("No")
    expect(page).to have_button("Save and mark as complete")
  end

  it "marks task as complete when selecting Yes", :capybara do
    expect(task).to be_not_started

    within :sidebar do
      click_link "Check description"
    end

    choose "Yes"
    click_button "Save and mark as complete"

    expect(page).to have_content("Description check was successfully saved")
    expect(task.reload).to be_completed
    expect(planning_application.reload.valid_description).to be true
  end

  it "shows error when no selection is made" do
    within :sidebar do
      click_link "Check description"
    end

    click_button "Save and mark as complete"

    expect(page).to have_content("Select whether the description is correct")
    expect(task.reload).to be_not_started
  end

  it "hides save button when application is determined" do
    planning_application.update!(status: "determined", determined_at: Time.current)

    within :sidebar do
      click_link "Check description"
    end

    expect(page).not_to have_button("Save and mark as complete")
  end

  it "warns when navigating away with unsaved changes", :js do
    within :sidebar do
      click_link "Check description"
    end

    choose "No"

    dismiss_confirm(text: "You have unsaved changes") do
      within :sidebar do
        click_link "Check fee"
      end
    end

    expect(page).to have_current_path(/check-description/)
  end

  it "allows navigation when no changes have been made", :js do
    within :sidebar do
      click_link "Check description"
      click_link "Check fee"
    end

    expect(page).to have_current_path(/check-fee/)
  end
end
