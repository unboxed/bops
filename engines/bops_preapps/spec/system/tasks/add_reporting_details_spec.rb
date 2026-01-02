# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Add reporting details task", type: :system, capybara: true do
  let(:local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user, local_authority:) }
  let(:planning_application) { create(:planning_application, :pre_application, :not_started, local_authority:) }
  let(:task) do
    planning_application.case_record.find_task_by_slug_path!(
      "check-and-validate/check-application-details/add-reporting-details"
    )
  end

  before do
    sign_in(user)
  end

  it "shows the task in the sidebar with not started status" do
    visit "/planning_applications/#{planning_application.reference}/validation/tasks"

    expect(task.status).to eq("not_started")

    within ".bops-sidebar" do
      expect(page).to have_link("Add reporting details")
    end
  end

  it "navigates to the task from the sidebar" do
    visit "/planning_applications/#{planning_application.reference}/validation/tasks"

    within ".bops-sidebar" do
      click_link "Add reporting details"
    end

    expect(page).to have_current_path(
      "/preapps/#{planning_application.reference}/check-and-validate/check-application-details/add-reporting-details"
    )
    expect(page).to have_selector("h1", text: "Add reporting details")
  end

  it "displays the form with correct label" do
    visit "/preapps/#{planning_application.reference}/check-and-validate/check-application-details/add-reporting-details"

    expect(page).to have_content("Select development type")
    expect(page).to have_content("Is the local planning authority the owner of this land?")
    expect(page).to have_button("Save and mark as complete")
    expect(page).to have_button("Save changes")
  end

  context "when application type has reporting types" do
    let!(:reporting_type) { create(:reporting_type, :major_dwellings) }

    before do
      planning_application.application_type.config.update!(reporting_types: [reporting_type.code])
    end

    it "displays reporting type options" do
      visit "/preapps/#{planning_application.reference}/check-and-validate/check-application-details/add-reporting-details"

      expect(page).to have_field(reporting_type.full_description)
    end

    it "shows validation error when no reporting type is selected on save and complete" do
      visit "/preapps/#{planning_application.reference}/check-and-validate/check-application-details/add-reporting-details"

      click_button "Save and mark as complete"

      expect(page).to have_content("Please select a development type for reporting")
      expect(task.reload).to be_not_started
    end

    it "allows saving draft without selecting reporting type" do
      expect(task).to be_not_started

      visit "/preapps/#{planning_application.reference}/check-and-validate/check-application-details/add-reporting-details"

      click_button "Save changes"

      expect(task.reload).to be_in_progress
    end

    it "marks task as complete when reporting type is selected" do
      expect(task).to be_not_started

      visit "/preapps/#{planning_application.reference}/check-and-validate/check-application-details/add-reporting-details"

      choose reporting_type.full_description
      click_button "Save and mark as complete"

      expect(page).to have_content("Reporting details were successfully saved")
      expect(task.reload).to be_completed
      expect(planning_application.reload.reporting_type_id).to eq(reporting_type.id)
    end

    it "saves regulation details when selected" do
      expect(task).to be_not_started

      visit "/preapps/#{planning_application.reference}/check-and-validate/check-application-details/add-reporting-details"

      choose reporting_type.full_description
      page.first(:radio_button, "Yes").choose
      within_fieldset("Is the local planning authority carrying out the works proposed?") do
        choose "Yes"
      end
      click_button "Save and mark as complete"

      expect(page).to have_content("Reporting details were successfully saved")
      expect(task.reload).to be_completed
      expect(planning_application.reload.regulation_3).to be true
      expect(planning_application.reload.regulation_4).to be false
    end

    context "when reporting type is already set" do
      before do
        planning_application.update!(reporting_type:)
      end

      it "pre-selects the reporting type" do
        visit "/preapps/#{planning_application.reference}/check-and-validate/check-application-details/add-reporting-details"

        expect(page).to have_checked_field(reporting_type.full_description)
      end
    end
  end

  context "when application type has no reporting types" do
    it "displays message about no applicable reporting types" do
      visit "/preapps/#{planning_application.reference}/check-and-validate/check-application-details/add-reporting-details"

      expect(page).to have_content("No applicable reporting types")
    end
  end

  it "hides save buttons when application is determined" do
    planning_application.update!(status: "determined", determined_at: Time.current)

    visit "/preapps/#{planning_application.reference}/check-and-validate/check-application-details/add-reporting-details"

    expect(page).not_to have_button("Save and mark as complete")
    expect(page).not_to have_button("Save changes")
  end
end
