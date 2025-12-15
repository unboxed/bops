# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Check fee task", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:proposal_details) do
    [
      {
        "question" => "Planning Pre-Application Advice Services",
        "responses" => [{"value" => "Householder (£100)"}],
        "metadata" => {}
      }
    ]
  end
  let(:planning_application) { create(:planning_application, :pre_application, :not_started, local_authority:, proposal_details:) }
  let(:user) { create(:user, local_authority:) }
  let(:task) { planning_application.case_record.find_task_by_slug_path!("check-and-validate/check-application-details/check-fee") }

  before do
    sign_in(user)
    visit "/planning_applications/#{planning_application.reference}/validation/tasks"
  end

  it "shows the task in the sidebar with not started status" do
    expect(task.status).to eq("not_started")

    within ".bops-sidebar" do
      expect(page).to have_link("Check fee")
    end
  end

  it "navigates to the task from the sidebar" do
    within ".bops-sidebar" do
      click_link "Check fee"
    end

    expect(page).to have_current_path("/preapps/#{planning_application.reference}/check-and-validate/check-application-details/check-fee")
    expect(page).to have_content("Check the application fee")
  end

  it "displays the form to check the fee" do
    within ".bops-sidebar" do
      click_link "Check fee"
    end

    expect(page).to have_content("Check the application fee")
    expect(page).to have_content("This fee was calculated based on the services requested by the applicant.")
    expect(page).to have_content("Fee calculation")
    expect(page).to have_content("Householder")
    expect(page).to have_content("£100")
    expect(page).to have_field("Yes")
    expect(page).to have_field("No")
    expect(page).to have_button("Save and mark as complete")
  end

  it "marks task as complete when selecting Yes" do
    expect(task).to be_not_started

    within ".bops-sidebar" do
      click_link "Check fee"
    end

    choose "Yes"
    click_button "Save and mark as complete"

    expect(page).to have_content("Fee check was successfully saved")
    expect(task.reload).to be_completed
    expect(planning_application.reload.valid_fee).to be true
  end

  it "redirects to validation request when selecting No" do
    expect(task).to be_not_started

    within ".bops-sidebar" do
      click_link "Check fee"
    end

    choose "No"
    click_button "Save and mark as complete"

    expect(page).to have_current_path(
      "/planning_applications/#{planning_application.reference}/validation/validation_requests/new?type=fee_change"
    )
    expect(task.reload).to be_in_progress
    expect(planning_application.reload.valid_fee).to be false

    within ".bops-sidebar" do
      expect(page).to have_content("Validation")
    end
  end

  it "shows error when no selection is made" do
    within ".bops-sidebar" do
      click_link "Check fee"
    end

    click_button "Save and mark as complete"

    expect(page).to have_content("Select whether the fee is correct")
    expect(task.reload).to be_not_started
  end

  it "hides save button when application is determined" do
    planning_application.update!(status: "determined", determined_at: Time.current)

    within ".bops-sidebar" do
      click_link "Check fee"
    end

    expect(page).not_to have_button("Save and mark as complete")
  end

  it "shows the Validation section in the sidebar" do
    within ".bops-sidebar" do
      click_link "Check fee"
    end

    within ".bops-sidebar" do
      expect(page).to have_content("Validation")
      expect(page).to have_link("Check fee")
    end
  end

  it "shows correct breadcrumb navigation" do
    within ".bops-sidebar" do
      click_link "Check fee"
    end

    expect(page).to have_link("Home")
    expect(page).to have_link("Application")
    expect(page).to have_link("Validation")
  end

  context "when fee change validation request exists" do
    let!(:fee_change_request) do
      create(:fee_change_validation_request,
        :pending,
        planning_application:,
        reason: "Fee is incorrect",
        suggestion: "Please pay the correct fee")
    end

    it "redirects to the validation request show page" do
      within ".bops-sidebar" do
        click_link "Check fee"
      end

      expect(page).to have_current_path(
        "/planning_applications/#{planning_application.reference}/validation/validation_requests/#{fee_change_request.id}"
      )
      expect(page).to have_content("View fee change request")
      expect(page).to have_content("Fee is incorrect")
      expect(page).to have_content("Please pay the correct fee")
      expect(page).to have_link("Delete request")
      expect(page).to have_link("Edit request")
    end

    it "marks task as completed when validation request is created" do
      expect(task.reload).to be_completed
    end

    it "resets task to not_started when validation request is deleted", js: true do
      expect(task.reload).to be_completed

      within ".bops-sidebar" do
        click_link "Check fee"
      end

      accept_confirm do
        click_link "Delete request"
      end

      expect(page).to have_content("Fee change request successfully deleted")
      expect(task.reload).to be_not_started
    end
  end

  context "when creating a fee change validation request" do
    it "marks task as completed after creating the request" do
      expect(task).to be_not_started

      within ".bops-sidebar" do
        click_link "Check fee"
      end

      choose "No"
      click_button "Save and mark as complete"

      expect(task.reload).to be_in_progress

      fill_in "Tell the applicant why the fee is incorrect", with: "The fee amount is wrong"
      fill_in "Tell the applicant what they need to do", with: "Please pay the correct amount"
      click_button "Save request"

      expect(page).to have_content("Fee change request successfully created")
      expect(task.reload).to be_completed
    end
  end
end
