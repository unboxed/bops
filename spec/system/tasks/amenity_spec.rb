# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Amenity task", type: :system do
  let(:user) { create(:user, local_authority:) }
  let(:local_authority) { create(:local_authority, :default) }
  let(:task) { planning_application.case_record.find_task_by_slug_path!("check-and-assess/assessment-summaries/amenity") }

  let(:planning_application) do
    create(:planning_application, :prior_approval, :in_assessment, local_authority:)
  end

  before do
    sign_in(user)
    visit "/planning_applications/#{planning_application.reference}"
    click_link "Check and assess"
  end

  it "can have an amenity assessment added" do
    within :sidebar do
      click_link "Amenity"
    end

    expect(page).to have_content("If a neighbour has objected")

    click_button "Save and mark as complete"

    expect(page).to have_content("Amenity assessment cannot be blank")

    fill_in "tasks_amenity_form[entry]", with: "The noise would be too loud"
    click_button "Save changes"

    expect(page).to have_selector("p", text: "The noise would be too loud")
    expect(page).to have_selector("textarea", text: "The noise would be too loud")
    expect(task).to be_in_progress

    click_button "Save and mark as complete"

    expect(page).to have_content("Amenity assessment was successfully saved")
    expect(task.reload).to be_completed
  end

  context "when trying to save a blank entry" do
    it "shows a validation error" do
      within :sidebar do
        click_link "Amenity"
      end

      fill_in "tasks_amenity_form[entry]", with: ""
      click_button "Save changes"

      expect(page).to have_content("Amenity assessment cannot be blank")
      expect(task.reload).to be_not_started
    end
  end

  context "when there is an existing amenity assessment" do
    before do
      planning_application.assessment_details.create!(category: "amenity", entry: "Initial assessment of noise impact", user:)
      task.start!
    end

    it "can edit the amenity assessment" do
      within :sidebar do
        click_link "Amenity"
      end

      expect(page).to have_selector("p", text: "Initial assessment of noise impact")
      expect(page).to have_selector("textarea", text: "Initial assessment of noise impact")
      expect(task).to be_in_progress

      fill_in "tasks_amenity_form[entry]", with: "Updated assessment: minimal impact on neighbouring amenity"
      click_button "Save and mark as complete"

      expect(page).to have_content("Amenity assessment was successfully saved")
      expect(page).to have_selector("p", text: "Updated assessment: minimal impact on neighbouring amenity")
      expect(task.reload).to be_completed
    end
  end
end
