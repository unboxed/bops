# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Meeting", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:planning_application) { create(:planning_application, :pre_application, local_authority:) }
  let(:task) { planning_application.case_record.find_task_by_slug_path!("check-and-assess/additional-services/meeting") }

  let(:user) { create(:user, local_authority:) }
  let(:tomorrow) { Date.tomorrow }

  before do
    sign_in(user)
    visit "/planning_applications/#{planning_application.reference}/assessment/tasks"
  end

  it "Allows adding a meeting" do
    within ".bops-sidebar" do
      click_link "Meeting"
    end

    expect(page).to have_current_path("/preapps/#{planning_application.reference}/check-and-assess/additional-services/meeting")
    expect(page).to have_content("No meetings have been recorded yet.")

    within "#new-meeting-form" do
      click_button "Add meeting"
    end

    expect(page).to have_content("Enter the date of the meeting")

    within "#new-meeting-form" do
      fill_in "Day", with: 32
      fill_in "Month", with: 12
      fill_in "Year", with: 2025

      click_button "Add meeting"
    end

    expect(page).to have_content("Enter a valid date for the meeting")

    within "#new-meeting-form" do
      fill_in "Day", with: tomorrow.day
      fill_in "Month", with: tomorrow.month
      fill_in "Year", with: tomorrow.year

      click_button "Add meeting"
    end

    expect(page).to have_content("Enter a date on or before today’s date")

    within "#new-meeting-form" do
      fill_in "Day", with: 2
      fill_in "Month", with: 10
      fill_in "Year", with: 2025

      fill_in "Add notes", with: "Discussed with applicant the constraints on development."
      click_button "Add meeting"
    end

    click_button "Save changes"

    expect(task.reload).to be_in_progress

    expect(planning_application.meetings.last.comment == "Discussed with applicant the constraints on development.")

    expect(page).not_to have_content("No meetings have been recorded yet.")

    within("#meeting-history") do
      expect(page).to have_content(planning_application.meetings.last.comment)
    end

    click_button "Save and mark as complete"
    expect(task.reload).to be_completed

    expect(page).to have_current_path("/preapps/#{planning_application.reference}/check-and-assess/additional-services/meeting")
  end
end
