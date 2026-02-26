# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Check requested services", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:planning_application) { create(:planning_application, :pre_application, status: "not_started", local_authority:) }
  let(:user) { create(:user, local_authority:) }
  let(:task) { planning_application.case_record.find_task_by_slug_path!("check-and-validate/check-application-details/check-requested-services") }

  before do
    sign_in(user)
    visit "/planning_applications/#{planning_application.reference}/validation"
  end

  it "Can complete and submit the form", :capybara do
    within ".bops-sidebar" do
      click_link "Check requested services"
    end

    expect(page).to have_current_path("/preapps/#{planning_application.reference}/check-and-validate/check-application-details/check-requested-services")
    expect(task).to be_not_started
    expect(page).to have_content("Select required services")

    expect(planning_application.additional_services.count).to eq 0

    check "Written advice"
    check "Meeting"

    click_button "Save and mark as complete"

    expect(page).to have_content("Requested services successfully saved")
    expect(task.reload).to be_completed
    expect(planning_application.additional_services.count).to eq 2

    click_button "Edit"

    expect(page).to have_content("Save and mark as complete")
    expect(task.reload).to be_in_progress
    uncheck "Meeting"

    click_button "Save and mark as complete"
    expect(page).to have_content("Requested services successfully saved")
    expect(planning_application.additional_services.count).to eq 1
  end
end
