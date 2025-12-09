# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Choose application type task", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:planning_application) { create(:planning_application, :pre_application, local_authority:) }
  let(:user) { create(:user, local_authority:) }
  let!(:application_type) { create(:application_type, :prior_approval, local_authority:) }
  let(:task) { planning_application.case_record.find_task_by_slug_path!("check-and-assess/complete-assessment/choose-application-type") }

  before do
    sign_in(user)
    visit "/planning_applications/#{planning_application.reference}/assessment/tasks"
  end

  it "Can complete and submit the form" do
    expect(task).to be_not_started

    within ".bops-sidebar" do
      click_link "Choose application type"
    end

    expect(page).to have_content("What application type would the applicant need to apply for next?")

    select "Prior Approval - Larger extension to a house", from: "What application type would the applicant need to apply for next?"

    click_button "Save and mark as complete"

    expect(page).to have_content("Recommended application type was successfully chosen")

    expect(planning_application.reload.recommended_application_type).to eq(application_type)
    expect(task.reload).to be_completed
  end

  it "shows validation errors when application type is not selected" do
    expect(task.status).to eq("not_started")

    within ".bops-sidebar" do
      click_link "Choose application type"
    end

    click_button "Save and mark as complete"

    expect(page).to have_content("There is a problem")
    expect(page).to have_content("Select the recommended type for the application")

    expect(planning_application.reload.recommended_application_type).to be_nil
    expect(task.reload).to be_not_started
  end

  it "displays the selected application type after completion" do
    expect(task).to be_not_started

    within ".bops-sidebar" do
      click_link "Choose application type"
    end

    select "Prior Approval - Larger extension to a house", from: "What application type would the applicant need to apply for next?"
    click_button "Save and mark as complete"

    expect(task.reload).to be_completed

    within ".bops-sidebar" do
      click_link "Choose application type"
    end

    expect(page).to have_content("What application type would the applicant need to apply for next?")
    expect(page).to have_content("Prior Approval - Larger extension to a house")
  end

  it "shows the previously selected application type in the dropdown" do
    planning_application.update!(recommended_application_type: application_type)
    task.complete!

    within ".bops-sidebar" do
      click_link "Choose application type"
    end

    select_field = find_field("What application type would the applicant need to apply for next?")
    expect(select_field.value).to eq(application_type.id.to_s)
  end
end
