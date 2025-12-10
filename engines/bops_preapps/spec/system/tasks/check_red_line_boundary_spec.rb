# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Check red line boundary task", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:boundary_geojson) do
    {
      type: "Feature",
      properties: {},
      geometry: {
        type: "Polygon",
        coordinates: [
          [
            [-0.054597, 51.537331],
            [-0.054588, 51.537287],
            [-0.054453, 51.537313],
            [-0.054597, 51.537331]
          ]
        ]
      }
    }
  end
  let(:planning_application) { create(:planning_application, :pre_application, :not_started, local_authority:, boundary_geojson:) }
  let(:user) { create(:user, local_authority:) }
  let(:task) { planning_application.case_record.find_task_by_slug_path!("check-and-validate/check-application-details/check-red-line-boundary") }

  before do
    sign_in(user)
    visit "/planning_applications/#{planning_application.reference}/validation/tasks"
  end

  it "shows the task in the sidebar with not started status" do
    expect(task.status).to eq("not_started")

    within ".bops-sidebar" do
      expect(page).to have_link("Check red line boundary")
    end
  end

  it "navigates to the task from the sidebar" do
    within ".bops-sidebar" do
      click_link "Check red line boundary"
    end

    expect(page).to have_current_path("/preapps/#{planning_application.reference}/check-and-validate/check-application-details/check-red-line-boundary")
    expect(page).to have_content("Check the digital red line boundary")
  end

  it "displays the form to check the red line boundary" do
    within ".bops-sidebar" do
      click_link "Check red line boundary"
    end

    expect(page).to have_content("Check the digital red line boundary")
    expect(page).to have_content("This digital red line boundary was submitted by the applicant.")
    expect(page).to have_field("Yes")
    expect(page).to have_field("No")
    expect(page).to have_button("Save and mark as complete")
  end

  it "marks task as complete when selecting Yes" do
    expect(task).to be_not_started

    within ".bops-sidebar" do
      click_link "Check red line boundary"
    end

    choose "Yes"
    click_button "Save and mark as complete"

    expect(page).to have_content("Red line boundary check was successfully saved")
    expect(task.reload).to be_completed
    expect(planning_application.reload.valid_red_line_boundary).to be true
  end

  it "redirects to validation request with sidebar when selecting No" do
    expect(task).to be_not_started

    within ".bops-sidebar" do
      click_link "Check red line boundary"
    end

    choose "No"
    click_button "Save and mark as complete"

    expect(page).to have_current_path(
      "/planning_applications/#{planning_application.reference}/validation/validation_requests/new?type=red_line_boundary_change"
    )
    expect(task.reload).to be_in_progress
    expect(planning_application.reload.valid_red_line_boundary).to be false

    within ".bops-sidebar" do
      expect(page).to have_content("Validation")
    end
  end

  it "completes full validation request flow and resets task on delete" do
    expect(task).to be_not_started

    within ".bops-sidebar" do
      click_link "Check red line boundary"
    end

    choose "No"
    click_button "Save and mark as complete"

    expect(page).to have_content("Proposed red line boundary change")

    fill_in "validation_request[reason]", with: "The boundary needs to include the garage"
    fill_in "validation_request[new_geojson]", with: boundary_geojson.to_json

    click_button "Save request"

    expect(page).to have_content("Proposed red line boundary change")
    expect(page).to have_content("The boundary needs to include the garage")
    expect(page).to have_content("Current red line boundary")
    expect(page).to have_content("Proposed red line boundary")
    expect(task.reload).to be_completed

    click_link "Delete request"

    expect(page).to have_current_path("/preapps/#{planning_application.reference}/check-and-validate/check-application-details/check-red-line-boundary")
    expect(page).to have_content("Check the digital red line boundary")
    expect(task.reload).to be_not_started
  end

  it "shows error when no selection is made" do
    within ".bops-sidebar" do
      click_link "Check red line boundary"
    end

    click_button "Save and mark as complete"

    expect(page).to have_content("Please select whether the red line boundary is correct")
    expect(task.reload).to be_not_started
  end

  it "hides save button when application is determined" do
    planning_application.update!(status: "determined", determined_at: Time.current)

    within ".bops-sidebar" do
      click_link "Check red line boundary"
    end

    expect(page).not_to have_button("Save and mark as complete")
  end

  it "shows the Validation section in the sidebar" do
    within ".bops-sidebar" do
      click_link "Check red line boundary"
    end

    within ".bops-sidebar" do
      expect(page).to have_content("Validation")
      expect(page).to have_link("Check red line boundary")
    end
  end

  it "shows correct breadcrumb navigation" do
    within ".bops-sidebar" do
      click_link "Check red line boundary"
    end

    expect(page).to have_link("Home")
    expect(page).to have_link("Application")
    expect(page).to have_link("Validation")
  end

  it "hides the draw red line boundary task when boundary_geojson is present" do
    within ".bops-sidebar" do
      expect(page).to have_link("Check red line boundary")
      expect(page).not_to have_link("Draw red line boundary")
    end
  end

  context "when boundary_geojson is blank" do
    let(:planning_application) { create(:planning_application, :pre_application, :not_started, local_authority:, boundary_geojson: nil) }

    it "shows draw red line boundary task and hides check red line boundary task" do
      within ".bops-sidebar" do
        expect(page).to have_link("Draw red line boundary")
        expect(page).not_to have_link("Check red line boundary")
      end
    end
  end
end
