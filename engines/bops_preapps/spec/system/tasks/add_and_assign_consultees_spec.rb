# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Add and assign consultees task", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:planning_application) { create(:planning_application, :pre_application, :not_started, local_authority:, consultation_required: true) }
  let(:user) { create(:user, local_authority:) }
  let(:task) { planning_application.case_record.find_task_by_slug_path!("consultees/add-and-assign-consultees") }

  before do
    sign_in(user)
    task.update!(hidden: false)
  end

  it "shows the task with not started status" do
    expect(task.status).to eq("not_started")
  end

  it "navigates to the task page" do
    visit "/preapps/#{planning_application.reference}/consultees/add-and-assign-consultees"

    expect(page).to have_content("Add and assign consultees")
  end

  it "displays the constraints selection section" do
    visit "/preapps/#{planning_application.reference}/consultees/add-and-assign-consultees"

    expect(page).to have_content("Select constraints that require consultation")
    expect(page).to have_content("Review the planning constraints and select which ones require consultation.")
  end

  it "displays the consultees assignment section" do
    visit "/preapps/#{planning_application.reference}/consultees/add-and-assign-consultees"

    expect(page).to have_content("Assign consultees to each constraint")
  end

  it "displays both save buttons" do
    visit "/preapps/#{planning_application.reference}/consultees/add-and-assign-consultees"

    expect(page).to have_button("Save and mark as complete")
    expect(page).to have_button("Save changes")
  end

  it "marks task as in progress when saving draft" do
    expect(task).to be_not_started

    visit "/preapps/#{planning_application.reference}/consultees/add-and-assign-consultees"

    click_button "Save changes"

    expect(page).to have_content("Consultee assignments were successfully saved")
    expect(task.reload).to be_in_progress
  end

  it "marks task as complete when saving and marking as complete" do
    expect(task).to be_not_started

    visit "/preapps/#{planning_application.reference}/consultees/add-and-assign-consultees"

    click_button "Save and mark as complete"

    expect(page).to have_content("Consultee assignments were successfully saved")
    expect(task.reload).to be_completed
  end

  it "stays on the task page after completion" do
    visit "/preapps/#{planning_application.reference}/consultees/add-and-assign-consultees"

    click_button "Save and mark as complete"

    expect(page).to have_current_path("/preapps/#{planning_application.reference}/consultees/add-and-assign-consultees")
  end

  it "shows correct breadcrumb navigation" do
    visit "/preapps/#{planning_application.reference}/consultees/add-and-assign-consultees"

    expect(page).to have_link("Home")
    expect(page).to have_link("Application")
    expect(page).to have_link("Consultation")
  end

  it "hides save buttons when application is determined" do
    planning_application.update!(status: "determined", determined_at: Time.current)

    visit "/preapps/#{planning_application.reference}/consultees/add-and-assign-consultees"

    expect(page).not_to have_button("Save and mark as complete")
    expect(page).not_to have_button("Save changes")
  end

  context "when the task is hidden" do
    before do
      task.update!(hidden: true)
    end

    it "is not visible in the task list until consultation is required" do
      expect(task).to be_hidden
    end
  end

  context "with constraints" do
    let!(:constraint) { create(:planning_application_constraint, planning_application:) }

    it "displays constraints for consultation selection" do
      visit "/preapps/#{planning_application.reference}/consultees/add-and-assign-consultees"

      expect(page).to have_css(".govuk-checkboxes")
    end
  end

  context "with existing consultees" do
    let!(:consultation) { planning_application.consultation || planning_application.create_consultation! }
    let!(:consultee) { create(:consultee, consultation:) }

    it "displays the consultees table" do
      visit "/preapps/#{planning_application.reference}/consultees/add-and-assign-consultees"

      expect(page).to have_css(".consultee-table")
    end
  end
end
