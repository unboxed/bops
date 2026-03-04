# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Add pre-commencement conditions task", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let!(:api_user) { create(:api_user, :planx, local_authority:) }
  let(:user) { create(:user, :assessor, local_authority:) }

  let(:planning_application) do
    create(:planning_application, :planning_permission, :in_assessment, local_authority:, api_user:, decision: "granted")
  end

  let(:reference) { planning_application.reference }
  let(:task) { planning_application.case_record.find_task_by_slug_path!("check-and-assess/complete-assessment/add-pre-commencement-conditions") }

  before do
    Current.user = user
    sign_in(user)
    visit "/planning_applications/#{reference}"
    click_link "Check and assess"
  end

  it "can add a pre-commencement condition" do
    within :sidebar do
      click_link "Add pre-commencement conditions"
    end

    expect(page).to have_content("Add pre-commencement conditions")

    toggle "Add new pre-commencement condition"

    fill_in "Enter title", with: "Title 1"
    fill_in "Enter condition", with: "Custom condition 1"
    fill_in "Enter reason", with: "Custom reason 1"
    click_button "Add pre-commencement condition"

    expect(page).to have_content("Pre-commencement condition was successfully added")
    expect(page).to have_content("Title 1")
    expect(page).to have_content("Custom condition 1")
    expect(task.reload).to be_in_progress
  end

  it "validates pre-commencement condition fields" do
    within :sidebar do
      click_link "Add pre-commencement conditions"
    end

    toggle "Add new pre-commencement condition"
    click_button "Add pre-commencement condition"

    expect(page).to have_content("Enter the title of this condition")
    expect(page).to have_content("Enter the text of this condition")
    expect(page).to have_content("Enter the reason for this condition")
  end

  it "can mark as complete with no conditions" do
    within :sidebar do
      click_link "Add pre-commencement conditions"
    end

    click_button "Save and mark as complete"

    expect(page).to have_content("Pre-commencement conditions were successfully saved")
    expect(task.reload).to be_completed
  end

  it "can save as draft" do
    within :sidebar do
      click_link "Add pre-commencement conditions"
    end

    toggle "Add new pre-commencement condition"
    fill_in "Enter title", with: "Title 1"
    fill_in "Enter condition", with: "Custom condition 1"
    fill_in "Enter reason", with: "Custom reason 1"
    click_button "Add pre-commencement condition"

    click_button "Save and come back later"

    expect(page).to have_content("Pre-commencement conditions draft was saved")
    expect(task.reload).to be_in_progress
  end

  context "with existing pre-commencement conditions" do
    let!(:condition) do
      Current.user = user
      planning_application.pre_commencement_condition_set.conditions.create!(
        title: "Existing title",
        text: "Existing text",
        reason: "Existing reason"
      )
    end

    it "can edit a pre-commencement condition and fields are pre-populated" do
      within :sidebar do
        click_link "Add pre-commencement conditions"
      end

      within("#conditions-list") do
        click_link "Edit"
      end

      expect(page).to have_field("Enter title", with: "Existing title")
      expect(page).to have_field("Enter condition", with: "Existing text")
      expect(page).to have_field("Enter reason", with: "Existing reason")

      fill_in "Enter title", with: "Updated title"
      fill_in "Enter condition", with: "Updated text"
      fill_in "Enter reason", with: "Updated reason"
      click_button "Save condition"

      expect(page).to have_content("Pre-commencement condition was successfully updated")
      expect(page).to have_content("Updated title")
    end

    it "can delete a pre-commencement condition when pending", capybara: true do
      within :sidebar do
        click_link "Add pre-commencement conditions"
      end

      within("#conditions-list") do
        accept_confirm do
          click_link "Remove"
        end
      end

      expect(page).to have_content("Pre-commencement condition was successfully removed")
      expect(planning_application.pre_commencement_condition_set.conditions.reload.count).to eq(0)
    end

    it "shows Not sent status tag for unsent conditions" do
      within :sidebar do
        click_link "Add pre-commencement conditions"
      end

      within("#condition_#{condition.id}") do
        expect(page).to have_selector(".govuk-tag", text: "Not sent")
        expect(page).to have_link("Edit")
        expect(page).to have_link("Remove")
      end
    end

    it "can confirm and send conditions to applicant", capybara: true do
      within :sidebar do
        click_link "Add pre-commencement conditions"
      end

      within("#condition_#{condition.id}") do
        expect(page).to have_selector(".govuk-tag", text: "Not sent")
      end

      click_button "Confirm and send to applicant"

      expect(page).to have_content("Pre-commencement conditions were sent to applicant")

      within("#condition_#{condition.id}") do
        expect(page).to have_selector(".govuk-tag", text: "Awaiting response")
        expect(page).not_to have_link("Edit")
        expect(page).not_to have_link("Remove")
        expect(page).to have_link("Cancel")
      end

      expect(page).to have_content("Waiting for the applicant to respond to the requests.")
    end

    it "cannot remove condition after it has been sent", capybara: true do
      within :sidebar do
        click_link "Add pre-commencement conditions"
      end

      click_button "Confirm and send to applicant"

      within("#condition_#{condition.id}") do
        expect(page).not_to have_link("Remove")
      end
    end

    it "can cancel an open validation request", capybara: true do
      within :sidebar do
        click_link "Add pre-commencement conditions"
      end

      click_button "Confirm and send to applicant"

      within("#condition_#{condition.id}") do
        expect(page).to have_selector(".govuk-tag", text: "Awaiting response")
        click_link "Cancel"
      end

      expect(page).to have_content("Explain to the applicant why this request is being cancelled")

      fill_in "Explain to the applicant why this request is being cancelled", with: "Made a typo"
      click_button "Confirm cancellation"

      expect(page).to have_content("Pre-commencement condition agreement request successfully cancelled")

      # Cancelled conditions are hidden from the list
      expect(page).not_to have_selector("#condition_#{condition.id}")
    end

    context "when condition has been rejected" do
      before do
        vr = condition.current_validation_request
        vr.update!(state: "closed", approved: false, rejection_reason: "Typo in condition", notified_at: 1.day.ago)
        create(:review, owner: condition.condition_set)
      end

      it "shows rejected status and allows editing" do
        within :sidebar do
          click_link "Add pre-commencement conditions"
        end

        within("#condition_#{condition.id}") do
          expect(page).to have_selector(".govuk-tag", text: "Rejected")
          expect(page).to have_content("Typo in condition")
          expect(page).to have_link("Edit")
          expect(page).not_to have_link("Remove")
        end
      end

      it "can edit a rejected condition and it creates a new pending request" do
        within :sidebar do
          click_link "Add pre-commencement conditions"
        end

        within("#condition_#{condition.id}") do
          click_link "Edit"
        end

        fill_in "Enter title", with: "Corrected title"
        fill_in "Enter condition", with: "Corrected text"
        fill_in "Enter reason", with: "Corrected reason"
        click_button "Save condition"

        expect(page).to have_content("Pre-commencement condition was successfully updated")

        within("#condition_#{condition.id}") do
          expect(page).to have_content("Corrected title")
          expect(page).to have_selector(".govuk-tag", text: "Not sent")
        end
      end
    end

    context "when all conditions are approved" do
      before do
        vr = condition.current_validation_request
        vr.update!(state: "closed", approved: true, notified_at: 1.day.ago)
        create(:review, owner: condition.condition_set)
      end

      it "shows Save and mark as complete button" do
        within :sidebar do
          click_link "Add pre-commencement conditions"
        end

        within("#condition_#{condition.id}") do
          expect(page).to have_selector(".govuk-tag", text: "Accepted")
        end

        click_button "Save and mark as complete"

        expect(page).to have_content("Pre-commencement conditions were successfully saved")
        expect(task.reload).to be_completed
      end
    end
  end
end
