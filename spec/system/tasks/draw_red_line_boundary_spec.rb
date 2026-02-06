# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Draw red line boundary task", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:planning_application) { create(:planning_application, :planning_permission, local_authority:) }
  let(:user) { create(:user, local_authority:) }
  let(:task) { planning_application.case_record.find_task_by_slug_path!("check-and-validate/check-application-details/draw-red-line-boundary") }
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

  before do
    sign_in(user)
    visit "/planning_applications/#{planning_application.reference}/validation/tasks"
  end

  it "shows the task in the sidebar with not started status" do
    expect(task.status).to eq("not_started")

    within :sidebar do
      expect(page).to have_link("Draw red line boundary")
    end
  end

  it "navigates to the task from the sidebar" do
    within :sidebar do
      click_link "Draw red line boundary"
    end

    expect(page).to have_current_path("/planning_applications/#{planning_application.reference}/check-and-validate/check-application-details/draw-red-line-boundary")
    expect(page).to have_content("Draw red line boundary")
  end

  it "displays the form to draw the red line boundary" do
    within :sidebar do
      click_link "Draw red line boundary"
    end

    expect(page).to have_content("Draw red line boundary")
    expect(page).to have_content("Red line site boundary on submission")
    expect(page).to have_content("Draw the red line site boundary")
    expect(page).to have_button("Save and mark as complete")
  end

  it "shows message when no sitemap document exists" do
    within :sidebar do
      click_link "Draw red line boundary"
    end

    expect(page).to have_content("No document has been tagged as a sitemap for this application")
    expect(page).to have_link("View all documents")
  end

  context "with a sitemap document" do
    let!(:document) { create(:document, planning_application:, tags: %w[sitePlan.existing]) }

    it "shows link to view the sitemap document" do
      within :sidebar do
        click_link "Draw red line boundary"
      end

      expect(page).to have_content("This digital red line boundary was submitted by the applicant on PlanX.")
      expect(page).to have_link("View sitemap document")
    end
  end

  context "with multiple sitemap documents" do
    let!(:document1) { create(:document, planning_application:, tags: %w[sitePlan.existing]) }
    let!(:document2) { create(:document, planning_application:, tags: %w[sitePlan.proposed]) }

    it "shows message about multiple documents" do
      within :sidebar do
        click_link "Draw red line boundary"
      end

      expect(page).to have_content("Multiple documents have been tagged as a sitemap for this application")
      expect(page).to have_link("View all documents")
    end
  end

  it "shows error when no boundary is drawn" do
    expect(task).to be_not_started

    within :sidebar do
      click_link "Draw red line boundary"
    end

    click_button "Save and mark as complete"

    expect(page).to have_content("Draw a red line boundary")
    expect(task.reload).to be_not_started
  end

  it "saves boundary and marks task as complete when boundary is drawn" do
    expect(task).to be_not_started
    expect(planning_application.boundary_geojson).to be_nil

    within :sidebar do
      click_link "Draw red line boundary"
    end

    find("input[name='tasks_draw_red_line_boundary_form[boundary_geojson]']").set(boundary_geojson.to_json)

    click_button "Save and mark as complete"

    expect(page).to have_content("Red line boundary was successfully saved")
    expect(task.reload).to be_completed
    expect(planning_application.reload.boundary_geojson).to eq(boundary_geojson.deep_stringify_keys)
    expect(planning_application.reload.valid_red_line_boundary).to be true
  end

  it "hides save button when application is determined" do
    planning_application.update!(decision: "granted", status: "determined", determined_at: Time.current)

    within :sidebar do
      click_link "Draw red line boundary"
    end

    expect(page).not_to have_button("Save and mark as complete")
  end

  it "shows the Validation section in the sidebar" do
    within :sidebar do
      click_link "Draw red line boundary"
    end

    within :sidebar do
      expect(page).to have_content("Validation")
      expect(page).to have_link("Draw red line boundary")
    end
  end

  it "shows the task status icon in the sidebar" do
    within :sidebar do
      click_link "Draw red line boundary"
    end

    within :sidebar do
      expect(page).to have_css(".bops-sidebar__task-icon")
    end
  end

  it "highlights the active task in the sidebar" do
    within :sidebar do
      click_link "Draw red line boundary"
    end

    within :sidebar do
      expect(page).to have_css(".bops-sidebar__task--active", text: "Draw red line boundary")
      expect(page).to have_css("a[aria-current='page']", text: "Draw red line boundary")
    end
  end

  it "shows correct breadcrumb navigation" do
    within :sidebar do
      click_link "Draw red line boundary"
    end

    expect(page).to have_link("Home")
    expect(page).to have_link("Application")
    expect(page).not_to have_link("Validation")
  end

  it "hides check red line boundary task when draw task is shown" do
    within :sidebar do
      expect(page).to have_link("Draw red line boundary")
      expect(page).not_to have_link("Check red line boundary")
    end
  end
end
