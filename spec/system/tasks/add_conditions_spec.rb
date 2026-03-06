# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Add conditions task", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let!(:api_user) { create(:api_user, :planx, local_authority:) }
  let(:user) { create(:user, :assessor, local_authority:) }

  let(:planning_application) do
    create(:planning_application, :planning_permission, :in_assessment, local_authority:, api_user:, decision: "granted")
  end

  let(:task) { planning_application.case_record.find_task_by_slug_path!("check-and-assess/complete-assessment/add-conditions") }

  before do
    sign_in(user)
    visit "/planning_applications/#{planning_application.reference}"
    click_link "Check and assess"
  end

  it "shows standard conditions pre-populated" do
    within :sidebar do
      click_link "Add conditions"
    end

    expect(page).to have_content("Add conditions")
    expect(page).to have_content("Time limit")
    expect(page).to have_content("Materials to match")
  end

  it "can add a condition" do
    within :sidebar do
      click_link "Add conditions"
    end

    toggle "Add condition"
    fill_in "Enter condition", with: "New custom condition"
    fill_in "Enter a reason for this condition", with: "Custom reason"
    click_button "Add condition to list"

    expect(page).to have_content("Condition was successfully added")
    expect(page).to have_content("New custom condition")
    expect(task.reload).to be_in_progress
  end

  it "validates condition fields" do
    within :sidebar do
      click_link "Add conditions"
    end

    toggle "Add condition"
    click_button "Add condition to list"

    expect(page).to have_content("Enter condition")
    expect(page).to have_content("Enter a reason for this condition")
  end

  it "can edit a condition" do
    within :sidebar do
      click_link "Add conditions"
    end

    within("#conditions-list") do
      first(:link, "Edit").click
    end

    fill_in "Enter condition", with: "Updated condition text"
    fill_in "Enter a reason for this condition", with: "Updated reason"
    click_button "Save condition"

    expect(page).to have_content("Condition was successfully updated")
    expect(page).to have_content("Updated condition text")
  end

  it "can delete a condition" do
    within :sidebar do
      click_link "Add conditions"
    end

    conditions_count = planning_application.condition_set.conditions.count
    click_button "Remove condition 1"

    expect(page).to have_content("Condition was successfully deleted")
    expect(planning_application.condition_set.conditions.reload.count).to eq(conditions_count - 1)
  end

  it "can mark conditions as complete" do
    within :sidebar do
      click_link "Add conditions"
    end

    click_button "Save and mark as complete"

    expect(page).to have_content("Conditions were successfully saved")
    expect(task.reload).to be_completed
  end

  it "can save as draft" do
    within :sidebar do
      click_link "Add conditions"
    end

    click_button "Save and come back later"

    expect(page).to have_content("Conditions draft was saved")
    expect(task.reload).to be_in_progress
  end

  context "when reviewing conditions" do
    let(:reviewer) { create(:user, :reviewer, local_authority:, name: "Bella Jones") }

    let(:planning_application) do
      create(:planning_application, :planning_permission, :awaiting_determination, local_authority:, api_user:, decision: :granted)
    end

    before do
      create(:recommendation, planning_application:)
      create(:decision, :householder_granted)

      condition_set = planning_application.condition_set
      condition_set.create_or_update_review!("complete")

      sign_in(reviewer)
      visit "/planning_applications/#{planning_application.reference}/review/tasks"
    end

    it "reviewer can see conditions in the review accordion" do
      expect(page).to have_content("Review conditions")
    end
  end
end
