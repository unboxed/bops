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
    expect(page).to have_content("Payment information")
    expect(page).to have_content("Fee paid")
    expect(page).to have_content("Payment reference")
    expect(page).to have_content("Session ID")
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

  it "shows validation request fields when selecting No", js: true do
    expect(task).to be_not_started

    within ".bops-sidebar" do
      click_link "Check fee"
    end

    choose "No"

    expect(page).to have_field("Tell the applicant why the fee is incorrect")
    expect(page).to have_field("Tell the applicant what they need to do")
  end

  it "shows validation errors when selecting No without reason and suggestion" do
    within ".bops-sidebar" do
      click_link "Check fee"
    end

    choose "No"
    click_button "Save and mark as complete"

    expect(page).to have_content("Tell the applicant why the fee is incorrect")
    expect(page).to have_content("Tell the applicant what they need to do")
    expect(task.reload).to be_not_started
  end

  it "creates fee change validation request when selecting No with reason and suggestion", js: true do
    expect(task).to be_not_started

    within ".bops-sidebar" do
      click_link "Check fee"
    end

    choose "No"
    fill_in "Tell the applicant why the fee is incorrect", with: "The fee amount is wrong"
    fill_in "Tell the applicant what they need to do", with: "Please pay the correct amount"
    click_button "Save and mark as complete"

    expect(page).to have_content("Fee check was successfully saved")
    expect(task.reload).to be_completed
    expect(planning_application.reload.valid_fee).to be false
    expect(planning_application.fee_change_validation_requests.count).to eq(1)
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

    before do
      task.complete!
    end

    it "shows the validation request on the task page" do
      within ".bops-sidebar" do
        click_link "Check fee"
      end

      expect(page).to have_current_path(
        "/preapps/#{planning_application.reference}/check-and-validate/check-application-details/check-fee"
      )
      expect(page).to have_content("Fee change request sent")
      expect(page).to have_content("Fee is incorrect")
      expect(page).to have_content("Please pay the correct fee")
      expect(page).to have_button("Delete request")
    end

    it "does not show the form when validation request exists" do
      within ".bops-sidebar" do
        click_link "Check fee"
      end

      expect(page).not_to have_field("Yes")
      expect(page).not_to have_field("No")
      expect(page).not_to have_button("Save and mark as complete")
    end

    it "resets task to not_started when validation request is deleted", js: true do
      expect(task.reload).to be_completed

      within ".bops-sidebar" do
        click_link "Check fee"
      end

      accept_confirm do
        click_button "Delete request"
      end

      expect(page).to have_content("Fee change request successfully deleted")
      expect(task.reload).to be_not_started
    end

    it "shows edit link when application is not started" do
      within ".bops-sidebar" do
        click_link "Check fee"
      end

      expect(page).to have_link("Edit request")
    end

    it "allows editing the validation request" do
      within ".bops-sidebar" do
        click_link "Check fee"
      end

      click_link "Edit request"

      expect(page).to have_content("Edit fee change request")
      expect(page).to have_field("Tell the applicant why the fee is incorrect", with: "Fee is incorrect")
      expect(page).to have_field("Tell the applicant what they need to do", with: "Please pay the correct fee")

      fill_in "Tell the applicant why the fee is incorrect", with: "Updated reason"
      fill_in "Tell the applicant what they need to do", with: "Updated suggestion"
      click_button "Update request"

      expect(page).to have_content("Fee change request successfully updated")
      expect(page).to have_content("Updated reason")
      expect(page).to have_content("Updated suggestion")
    end
  end

  context "when application is invalidated with fee change request" do
    let!(:fee_change_request) do
      create(:fee_change_validation_request,
        :open,
        planning_application:,
        reason: "Fee is incorrect",
        suggestion: "Please pay the correct fee")
    end

    before do
      task.complete!
      planning_application.update!(status: "invalidated")
    end

    it "shows cancel link when application is invalidated" do
      within ".bops-sidebar" do
        click_link "Check fee"
      end

      expect(page).to have_link("Cancel request")
      expect(page).not_to have_link("Edit request")
      expect(page).not_to have_button("Delete request")
    end

    it "allows cancelling the validation request" do
      within ".bops-sidebar" do
        click_link "Check fee"
      end

      click_link "Cancel request"

      expect(page).to have_content("Cancel fee change request")
      expect(page).to have_content("Request to be cancelled")
      expect(page).to have_content("Fee is incorrect")

      fill_in "Explain to the applicant why this request is being cancelled", with: "No longer needed"
      click_button "Confirm cancellation"

      expect(page).to have_content("Fee change request successfully cancelled")
      expect(task.reload).to be_not_started
      expect(fee_change_request.reload).to be_cancelled
    end
  end
end
