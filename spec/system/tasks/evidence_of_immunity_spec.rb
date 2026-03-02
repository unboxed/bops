# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Evidence of immunity task", type: :system do
  let(:user) { create(:user, local_authority:) }
  let(:local_authority) { create(:local_authority, :default) }
  let(:task) { planning_application.case_record.find_task_by_slug_path!("check-and-assess/assess-immunity/evidence-of-immunity") }

  let(:planning_application) do
    create(:planning_application, :ldc_existing, :in_assessment, local_authority:)
  end

  before do
    sign_in(user)
    visit "/planning_applications/#{planning_application.reference}"
    click_link "Check and assess"
  end

  it "can have evidence of immunity added" do
    within :sidebar do
      click_link "Evidence of immunity"
    end

    expect(page).to have_content("Review the evidence provided")

    click_button "Save and mark as complete"

    expect(page).to have_content("Evidence of immunity cannot be blank")

    fill_in "Evidence of immunity assessment", with: "Sufficient evidence of continuous use for 4 years"
    click_button "Save changes"

    expect(page).to have_selector("p", text: "Sufficient evidence of continuous use for 4 years")
    expect(page).to have_selector("textarea", text: "Sufficient evidence of continuous use for 4 years")
    expect(task).to be_in_progress

    click_button "Save and mark as complete"

    expect(page).to have_content("Evidence of immunity was successfully saved")
    expect(task.reload).to be_completed
  end

  context "when trying to save a blank entry" do
    it "shows a validation error" do
      within :sidebar do
        click_link "Evidence of immunity"
      end

      fill_in "Evidence of immunity assessment", with: ""
      click_button "Save changes"

      expect(page).to have_content("Evidence of immunity cannot be blank")
      expect(task.reload).to be_not_started
    end
  end

  context "when there is an existing evidence assessment" do
    before do
      planning_application.assessment_details.create!(category: "evidence_of_immunity", entry: "Initial evidence review", user:)
      task.start!
    end

    it "can edit the evidence assessment" do
      within :sidebar do
        click_link "Evidence of immunity"
      end

      expect(page).to have_selector("p", text: "Initial evidence review")
      expect(page).to have_selector("textarea", text: "Initial evidence review")
      expect(task).to be_in_progress

      fill_in "Evidence of immunity assessment", with: "Updated: evidence covers the full 4-year period with no gaps"
      click_button "Save and mark as complete"

      expect(page).to have_content("Evidence of immunity was successfully saved")
      expect(page).to have_selector("p", text: "Updated: evidence covers the full 4-year period with no gaps")
      expect(task.reload).to be_completed
    end
  end
end
