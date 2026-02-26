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

    fill_in "Amenity assessment", with: "The noise would be too loud"
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

      fill_in "Amenity assessment", with: ""
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

      fill_in "Amenity assessment", with: "Updated assessment: minimal impact on neighbouring amenity"
      click_button "Save and mark as complete"

      expect(page).to have_content("Amenity assessment was successfully saved")
      expect(page).to have_selector("p", text: "Updated assessment: minimal impact on neighbouring amenity")
      expect(task.reload).to be_completed
    end
  end

  context "when the reviewer has rejected the amenity assessment" do
    let(:reviewer) { create(:user, :reviewer, local_authority:, name: "Bella Jones") }

    let!(:rejected_assessment_detail) do
      planning_application.assessment_details.create!(
        category: "amenity",
        entry: "Original amenity assessment",
        assessment_status: :complete,
        review_status: :complete,
        reviewer_verdict: :rejected,
        user:
      ).tap do |ad|
        Current.set(user: reviewer) do
          ad.create_comment!(text: "Please reconsider the noise impact")
        end
      end
    end

    before do
      task.complete!
    end

    it "shows the reviewer comment and creates a new assessment detail on save" do
      within :sidebar do
        click_link "Amenity"
      end

      within(".comment-component") do
        expect(page).to have_content("Reviewer comment")
        expect(page).to have_content("Please reconsider the noise impact")
      end

      expect(page).to have_selector("textarea", text: "Original amenity assessment")

      fill_in "Amenity assessment", with: "Revised assessment: noise impact is minimal"
      click_button "Save and mark as complete"

      expect(page).to have_content("Amenity assessment was successfully saved")
      expect(page).to have_selector("p", text: "Revised assessment: noise impact is minimal")
      expect(task.reload).to be_completed

      amenity_details = planning_application.assessment_details.where(category: "amenity")
      expect(amenity_details.count).to eq(2)
      expect(rejected_assessment_detail.reload).to have_attributes(
        entry: "Original amenity assessment",
        review_status: "complete",
        reviewer_verdict: "rejected"
      )

      new_detail = amenity_details.where.not(id: rejected_assessment_detail.id).first
      expect(new_detail).to have_attributes(
        entry: "Revised assessment: noise impact is minimal",
        assessment_status: "complete",
        review_status: nil,
        reviewer_verdict: nil
      )
    end
  end

  context "when reviewing the amenity assessment" do
    let(:assessor) { create(:user, :assessor, local_authority:, name: "Alice Smith") }
    let(:reviewer) { create(:user, :reviewer, local_authority:, name: "Bella Jones") }

    let(:planning_application) do
      create(:planning_application, :prior_approval, :awaiting_determination, local_authority:, decision: :granted)
    end

    let!(:amenity) do
      travel_to(Time.zone.local(2024, 11, 28, 11, 30)) do
        planning_application.assessment_details.create!(
          category: "amenity",
          entry: "Assessment of noise impact on neighbours",
          assessment_status: :complete,
          user: assessor
        )
      end
    end

    before do
      create(:recommendation, planning_application:)
      create(:decision, :pa_granted)
      create(:decision, :pa_not_required)

      sign_in(reviewer)
      visit "/planning_applications/#{planning_application.reference}/review/tasks"
    end

    it "reviewer can accept the amenity assessment" do
      click_button "Amenity assessment"

      within("#amenity_section") do
        expect(find(".govuk-tag")).to have_content("Not started")

        within("#amenity_block") do
          expect(page).to have_content("Assessment of noise impact on neighbours")
        end
      end

      within("#amenity_footer") do
        choose "Agree"
        click_button("Save and mark as complete")
      end

      expect(page).to have_content("Review of amenity was successfully updated")

      within("#amenity_section") do
        expect(find(".govuk-tag")).to have_content("Completed")
      end
    end

    it "reviewer can reject and assessor can update via task, showing Updated status" do
      click_button "Amenity assessment"

      within("#amenity_footer") do
        choose "Return with comments"
        fill_in "Add a comment", with: "Noise assessment needs more detail"
        click_button("Save and mark as complete")
      end

      expect(page).to have_content("Review of amenity was successfully updated")

      click_link("Sign off recommendation")
      choose("No (return the case for assessment)")
      fill_in "Explain to the officer why the case is being returned", with: "Recommendation challenged"
      click_button("Save and mark as complete")

      within("#amenity_section") do
        expect(find(".govuk-tag")).to have_content("Awaiting changes")
      end

      # Assessor updates amenity via the task form
      sign_out(reviewer)
      travel 1.day
      sign_in(assessor)
      visit "/planning_applications/#{planning_application.reference}"
      click_link("Check and assess")

      within(:sidebar) do
        click_link("Amenity")
      end

      within(".comment-component") do
        expect(page).to have_content("Reviewer comment")
        expect(page).to have_content("Noise assessment needs more detail")
      end

      fill_in "Amenity assessment", with: "Revised: minimal noise impact on neighbouring amenity"
      click_button("Save and mark as complete")
      expect(page).to have_content("Amenity assessment was successfully saved")

      # Assessor resubmits recommendation
      visit "/planning_applications/#{planning_application.reference}/assessment/tasks"
      click_link("Make draft recommendation")
      click_button("Update assessment")
      click_link("Review and submit recommendation")
      click_button("Submit recommendation")

      # Reviewer returns and sees Updated status
      sign_out(assessor)
      sign_in(reviewer)
      visit "/planning_applications/#{planning_application.reference}/review/tasks"

      within("#amenity_section") do
        expect(find(".govuk-tag")).to have_content("Updated")
      end

      click_button "Amenity assessment"

      within("#amenity_block") do
        expect(page).to have_content("Revised: minimal noise impact on neighbouring amenity")
      end

      within("#amenity_footer") do
        choose "Agree"
        click_button("Save and mark as complete")
      end

      within("#amenity_section") do
        expect(find(".govuk-tag")).to have_content("Completed")
      end
    end
  end
end
