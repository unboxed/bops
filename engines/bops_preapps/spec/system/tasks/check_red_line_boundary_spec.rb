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

    expect(page).to have_content("Red line boundary change request sent")
    expect(page).to have_content("The boundary needs to include the garage")
    expect(page).to have_content("Current red line boundary")
    expect(page).to have_content("Proposed red line boundary")
    expect(task.reload).to be_completed

    click_button "Delete request"

    expect(page).to have_current_path("/preapps/#{planning_application.reference}/check-and-validate/check-application-details/check-red-line-boundary")
    expect(page).to have_content("Check the digital red line boundary")
    expect(task.reload).to be_not_started
  end

  it "shows error when no selection is made" do
    within ".bops-sidebar" do
      click_link "Check red line boundary"
    end

    click_button "Save and mark as complete"

    expect(page).to have_content("Select whether the red line boundary is correct")
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

  it "highlights the active task in the sidebar" do
    within ".bops-sidebar" do
      click_link "Check red line boundary"
    end

    within ".bops-sidebar" do
      expect(page).to have_css(".bops-sidebar__task--active", text: "Check red line boundary")
      expect(page).to have_css("a[aria-current='page']", text: "Check red line boundary")
    end
  end

  it "shows correct breadcrumb navigation" do
    within ".bops-sidebar" do
      click_link "Check red line boundary"
    end

    expect(page).to have_link("Home")
    expect(page).to have_link("Application")
    expect(page).not_to have_link("Validation")
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

  context "when applicant has approved red line boundary change" do
    let(:new_geojson) do
      {
        type: "Feature",
        properties: {},
        geometry: {
          type: "Polygon",
          coordinates: [
            [
              [-0.054600, 51.537335],
              [-0.054590, 51.537290],
              [-0.054455, 51.537315],
              [-0.054600, 51.537335]
            ]
          ]
        }
      }
    end

    let!(:validation_request) do
      create(:red_line_boundary_change_validation_request,
        :closed,
        planning_application:,
        reason: "Boundary needs to include garage",
        new_geojson: new_geojson,
        original_geojson: boundary_geojson,
        approved: true)
    end

    before do
      task.action_required!
    end

    it "shows the task with action_required status" do
      expect(task.reload).to be_action_required
    end

    it "shows approval message on the task page" do
      within ".bops-sidebar" do
        click_link "Check red line boundary"
      end

      expect(page).to have_content("Red line boundary change approved")
      expect(page).to have_content("Change to red line boundary has been approved by the applicant")
    end

    it "shows save and mark as complete button" do
      within ".bops-sidebar" do
        click_link "Check red line boundary"
      end

      expect(page).to have_button("Save and mark as complete")
    end

    it "marks red line as valid and completes the task" do
      expect(task.reload).to be_action_required

      within ".bops-sidebar" do
        click_link "Check red line boundary"
      end

      click_button "Save and mark as complete"

      expect(page).to have_content("Red line boundary was successfully marked as valid")
      expect(task.reload).to be_completed
      expect(planning_application.reload.valid_red_line_boundary).to be true
    end
  end

  context "when applicant has rejected red line boundary change" do
    let(:new_geojson) do
      {
        type: "Feature",
        properties: {},
        geometry: {
          type: "Polygon",
          coordinates: [
            [
              [-0.054600, 51.537335],
              [-0.054590, 51.537290],
              [-0.054455, 51.537315],
              [-0.054600, 51.537335]
            ]
          ]
        }
      }
    end

    let!(:validation_request) do
      create(:red_line_boundary_change_validation_request,
        :closed,
        planning_application:,
        reason: "Boundary needs to include garage",
        new_geojson: new_geojson,
        original_geojson: boundary_geojson,
        approved: false,
        rejection_reason: "The garage is not part of my property")
    end

    before do
      task.action_required!
    end

    it "shows the task with action_required status" do
      expect(task.reload).to be_action_required
    end

    it "shows rejection message on the task page" do
      within ".bops-sidebar" do
        click_link "Check red line boundary"
      end

      expect(page).to have_content("Red line boundary change rejected")
      expect(page).to have_content("Applicant rejected this proposed red line boundary")
      expect(page).to have_content("The garage is not part of my property")
    end

    it "shows Yes/No form to re-check the boundary" do
      within ".bops-sidebar" do
        click_link "Check red line boundary"
      end

      expect(page).to have_field("Yes")
      expect(page).to have_field("No")
      expect(page).to have_button("Save and mark as complete")
    end

    it "marks boundary as valid and completes task when selecting Yes" do
      expect(task.reload).to be_action_required

      within ".bops-sidebar" do
        click_link "Check red line boundary"
      end

      choose "Yes"
      click_button "Save and mark as complete"

      expect(page).to have_content("Red line boundary check was successfully saved")
      expect(task.reload).to be_completed
      expect(planning_application.reload.valid_red_line_boundary).to be true
    end

    it "redirects to new validation request when selecting No" do
      expect(task.reload).to be_action_required

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
    end
  end

  context "when validation request is pending" do
    let(:new_geojson) do
      {
        type: "Feature",
        properties: {},
        geometry: {
          type: "Polygon",
          coordinates: [
            [
              [-0.054600, 51.537335],
              [-0.054590, 51.537290],
              [-0.054455, 51.537315],
              [-0.054600, 51.537335]
            ]
          ]
        }
      }
    end

    let!(:validation_request) do
      create(:red_line_boundary_change_validation_request,
        :pending,
        planning_application:,
        reason: "Boundary needs to include garage",
        new_geojson: new_geojson,
        original_geojson: boundary_geojson)
    end

    before do
      task.complete!
    end

    it "shows the validation request was sent on the task page" do
      within ".bops-sidebar" do
        click_link "Check red line boundary"
      end

      expect(page).to have_content("Red line boundary change request sent")
      expect(page).to have_content("Boundary needs to include garage")
      expect(page).to have_content("Waiting for applicant response")
    end

    it "does not show the form when validation request exists" do
      within ".bops-sidebar" do
        click_link "Check red line boundary"
      end

      expect(page).not_to have_field("Yes")
      expect(page).not_to have_field("No")
      expect(page).not_to have_button("Save and mark as complete")
    end

    it "shows delete button but not cancel link when application is not started" do
      within ".bops-sidebar" do
        click_link "Check red line boundary"
      end

      expect(page).to have_button("Delete request")
      expect(page).not_to have_link("Cancel request")
    end
  end

  context "when application is invalidated with open validation request" do
    let(:new_geojson) do
      {
        type: "Feature",
        properties: {},
        geometry: {
          type: "Polygon",
          coordinates: [
            [
              [-0.054600, 51.537335],
              [-0.054590, 51.537290],
              [-0.054455, 51.537315],
              [-0.054600, 51.537335]
            ]
          ]
        }
      }
    end

    let!(:validation_request) do
      create(:red_line_boundary_change_validation_request,
        :open,
        planning_application:,
        reason: "Boundary needs to include garage",
        new_geojson: new_geojson,
        original_geojson: boundary_geojson)
    end

    before do
      task.complete!
      planning_application.update!(status: "invalidated")
    end

    it "shows cancel link when application is invalidated" do
      within ".bops-sidebar" do
        click_link "Check red line boundary"
      end

      expect(page).to have_link("Cancel request")
      expect(page).not_to have_button("Delete request")
    end

    it "allows cancelling the validation request and resets task to not started" do
      within ".bops-sidebar" do
        click_link "Check red line boundary"
      end

      click_link "Cancel request"

      expect(page).to have_content("Cancel validation request")

      fill_in "Explain to the applicant why this request is being cancelled", with: "Boundary was correct after all"
      click_button "Confirm cancellation"

      expect(page).to have_content("Red line boundary change request successfully cancelled")
      expect(validation_request.reload).to be_cancelled
      expect(task.reload).to be_not_started
    end

    it "shows validation error when cancel reason is blank" do
      within ".bops-sidebar" do
        click_link "Check red line boundary"
      end

      click_link "Cancel request"
      click_button "Confirm cancellation"

      expect(page).to have_content("Cancel reason can't be blank")
      expect(validation_request.reload).not_to be_cancelled
    end
  end

  context "when applicant responds to red line boundary change request" do
    let(:new_geojson) do
      {
        type: "Feature",
        properties: {},
        geometry: {
          type: "Polygon",
          coordinates: [
            [
              [-0.054600, 51.537335],
              [-0.054590, 51.537290],
              [-0.054455, 51.537315],
              [-0.054600, 51.537335]
            ]
          ]
        }
      }
    end

    let!(:validation_request) do
      create(:red_line_boundary_change_validation_request,
        :open,
        planning_application:,
        reason: "Boundary needs to include garage",
        new_geojson: new_geojson,
        original_geojson: boundary_geojson)
    end

    before do
      task.complete!
      planning_application.update!(status: "invalidated")
    end

    it "sets task to action_required when applicant approves the request" do
      expect(task.reload).to be_completed

      validation_request.update!(approved: true)
      validation_request.close!

      expect(task.reload).to be_action_required
    end

    it "sets task to action_required when applicant rejects the request" do
      expect(task.reload).to be_completed

      validation_request.update!(approved: false, rejection_reason: "The garage is not part of my property")
      validation_request.close!

      expect(task.reload).to be_action_required
    end
  end
end
