# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Permitted development rights task", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user, :assessor, local_authority:) }
  let(:planning_application) do
    create(:planning_application, :ldc_proposed, :in_assessment, local_authority:)
  end
  let(:task) do
    planning_application.case_record.find_task_by_slug_path!(
      "check-and-assess/check-application/permitted-development-rights"
    )
  end

  before do
    sign_in(user)
    visit "/planning_applications/#{planning_application.reference}/assessment/tasks"
  end

  it "shows the task in the sidebar with not started status" do
    expect(task.status).to eq("not_started")

    within ".bops-sidebar" do
      expect(page).to have_link("Permitted development rights")
    end
  end

  it "navigates to the task from the sidebar" do
    within ".bops-sidebar" do
      click_link "Permitted development rights"
    end

    expect(page).to have_content("Have the permitted development rights relevant for this application been removed?")
  end

  it "shows a warning about public availability of information" do
    within ".bops-sidebar" do
      click_link "Permitted development rights"
    end

    within(".govuk-warning-text") do
      expect(page).to have_content("This information will be made publicly available.")
    end
  end

  it "shows a validation error when no option is selected" do
    within ".bops-sidebar" do
      click_link "Permitted development rights"
    end

    click_button "Save and mark as complete"

    within(".govuk-error-summary") do
      expect(page).to have_content("Select whether permitted development rights have been removed.")
    end
    expect(task.reload).to be_not_started
  end

  it "shows a validation error when 'Yes' is selected without a reason" do
    within ".bops-sidebar" do
      click_link "Permitted development rights"
    end

    choose "Yes"
    click_button "Save and mark as complete"

    within(".govuk-error-summary") do
      expect(page).to have_content("Explain why the permitted development rights have been removed")
    end
    expect(task.reload).to be_not_started
  end

  it "saves and completes when 'No' is selected" do
    within ".bops-sidebar" do
      click_link "Permitted development rights"
    end

    choose "No"
    click_button "Save and mark as complete"

    expect(page).to have_content("Successfully confirmed permitted development rights")
    expect(task.reload).to be_completed
    expect(planning_application.permitted_development_rights.last).to have_attributes(
      removed: false,
      status: "complete",
      assessor: user
    )
  end

  it "saves and completes when 'Yes' is selected with a reason" do
    within ".bops-sidebar" do
      click_link "Permitted development rights"
    end

    choose "Yes"
    fill_in "Describe how permitted development rights have been removed", with: "Article 4 direction applies"
    click_button "Save and mark as complete"

    expect(page).to have_content("Successfully confirmed permitted development rights")
    expect(task.reload).to be_completed
    expect(planning_application.permitted_development_rights.last).to have_attributes(
      removed: true,
      removed_reason: "Article 4 direction applies",
      status: "complete",
      assessor: user
    )
  end

  it "saves a draft and marks the task as in progress" do
    within ".bops-sidebar" do
      click_link "Permitted development rights"
    end

    choose "No"
    click_button "Save changes"

    expect(task.reload).to be_in_progress
    expect(planning_application.permitted_development_rights.last).to have_attributes(
      removed: false,
      status: "in_progress",
      assessor: user
    )
  end

  context "when the permitted development right is to be reviewed" do
    let!(:permitted_development_right) do
      create(:permitted_development_right,
        planning_application:,
        assessor: user,
        removed: false,
        status: "to_be_reviewed")
    end

    before { task.start! }

    it "creates a new permitted development right record when saving a draft" do
      within ".bops-sidebar" do
        click_link "Permitted development rights"
      end

      choose "No"
      click_button "Save changes"

      expect(task.reload).to be_in_progress
      expect(planning_application.permitted_development_rights.last).to have_attributes(
        removed: false,
        status: "updated",
        assessor: user
      )
    end
  end

  context "when an existing permitted development right record exists" do
    let!(:permitted_development_right) do
      create(:permitted_development_right,
        planning_application:,
        assessor: user,
        removed: true,
        removed_reason: "Article 4 direction applies",
        status: "in_progress")
    end

    before { task.start! }

    it "pre-populates the form with existing values" do
      within ".bops-sidebar" do
        click_link "Permitted development rights"
      end

      expect(page).to have_field("Yes", checked: true)
      expect(page).to have_field(
        "Describe how permitted development rights have been removed",
        with: "Article 4 direction applies"
      )
    end

    it "clears the removed_reason when changing from 'Yes' to 'No'" do
      within ".bops-sidebar" do
        click_link "Permitted development rights"
      end

      choose "No"
      click_button "Save and mark as complete"

      expect(task.reload).to be_completed
      expect(planning_application.permitted_development_rights.last).to have_attributes(
        removed: false,
        removed_reason: nil
      )
    end
  end
end
