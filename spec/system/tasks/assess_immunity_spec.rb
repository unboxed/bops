# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Assess immunity task", type: :system do
  let(:user) { create(:user, local_authority:) }
  let(:local_authority) { create(:local_authority, :default) }
  let(:task) { planning_application.case_record.find_task_by_slug_path!("check-and-assess/assess-immunity/assess-immunity") }

  let(:planning_application) do
    create(:planning_application, :ldc_existing, :in_assessment, local_authority:)
  end

  before do
    sign_in(user)
    visit "/planning_applications/#{planning_application.reference}"
    click_link "Check and assess"
  end

  it "can have an immunity assessment added" do
    within :sidebar do
      click_link "Assess immunity"
    end

    expect(page).to have_content("Assess whether the development is immune")

    click_button "Save and mark as complete"

    expect(page).to have_content("Immunity assessment cannot be blank")

    fill_in "Immunity assessment", with: "The development is immune from enforcement"
    click_button "Save changes"

    expect(page).to have_selector("p", text: "The development is immune from enforcement")
    expect(page).to have_selector("textarea", text: "The development is immune from enforcement")
    expect(task).to be_in_progress

    click_button "Save and mark as complete"

    expect(page).to have_content("Immunity assessment was successfully saved")
    expect(task.reload).to be_completed
  end

  context "when trying to save a blank entry" do
    it "shows a validation error" do
      within :sidebar do
        click_link "Assess immunity"
      end

      fill_in "Immunity assessment", with: ""
      click_button "Save changes"

      expect(page).to have_content("Immunity assessment cannot be blank")
      expect(task.reload).to be_not_started
    end
  end

  context "when there is an existing immunity assessment" do
    before do
      planning_application.assessment_details.create!(category: "assess_immunity", entry: "Initial immunity assessment", user:)
      task.start!
    end

    it "can edit the immunity assessment" do
      within :sidebar do
        click_link "Assess immunity"
      end

      expect(page).to have_selector("p", text: "Initial immunity assessment")
      expect(page).to have_selector("textarea", text: "Initial immunity assessment")
      expect(task).to be_in_progress

      fill_in "Immunity assessment", with: "Updated: the development is immune under the 4-year rule"
      click_button "Save and mark as complete"

      expect(page).to have_content("Immunity assessment was successfully saved")
      expect(page).to have_selector("p", text: "Updated: the development is immune under the 4-year rule")
      expect(task.reload).to be_completed
    end
  end
end
