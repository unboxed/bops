# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Add pre-commencement conditions task", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let!(:api_user) { create(:api_user, :planx, local_authority:) }
  let(:user) { create(:user, :assessor, local_authority:) }

  let(:planning_application) do
    create(:planning_application, :planning_permission, :in_assessment, local_authority:, api_user:, decision: "granted")
  end

  let(:task) { planning_application.case_record.find_task_by_slug_path!("check-and-assess/complete-assessment/add-pre-commencement-conditions") }

  before do
    Current.user = user
    sign_in(user)
    visit "/planning_applications/#{planning_application.reference}"
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

  context "with existing pre-commencement conditions" do
    let!(:condition) do
      Current.user = user
      planning_application.pre_commencement_condition_set.conditions.create!(
        title: "Existing title",
        text: "Existing text",
        reason: "Existing reason"
      )
    end

    it "can edit a pre-commencement condition" do
      within :sidebar do
        click_link "Add pre-commencement conditions"
      end

      within("#conditions-list") do
        click_link "Edit"
      end

      fill_in "Enter title", with: "Updated title"
      fill_in "Enter condition", with: "Updated text"
      fill_in "Enter reason", with: "Updated reason"
      click_button "Save condition"

      expect(page).to have_content("Pre-commencement condition was successfully updated")
      expect(page).to have_content("Updated title")
    end

    it "can delete a pre-commencement condition" do
      within :sidebar do
        click_link "Add pre-commencement conditions"
      end

      click_button "Remove condition 1"

      expect(page).to have_content("Pre-commencement condition was successfully deleted")
      expect(planning_application.pre_commencement_condition_set.conditions.reload.count).to eq(0)
    end
  end
end
