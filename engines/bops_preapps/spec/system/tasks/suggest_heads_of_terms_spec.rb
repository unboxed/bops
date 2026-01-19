# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Suggest heads of terms task", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:planning_application) { create(:planning_application, :pre_application, local_authority:) }
  let!(:assessor) { create(:user, :assessor, local_authority:) }

  let(:task) { planning_application.case_record.find_task_by_slug_path!("check-and-assess/assessment-summaries/suggest-heads-of-terms") }
  let(:heads_of_term) { planning_application.heads_of_term }

  before do
    Current.user = assessor
    travel_to(Time.zone.local(2024, 4, 17, 12, 30))
    sign_in assessor

    visit "/planning_applications/#{planning_application.reference}/assessment/tasks"

    within ".bops-sidebar" do
      click_link "Suggest heads of terms"
    end
  end

  it "displays the form to add heads of terms when none have been added" do
    expect(task).to be_not_started
    expect(page).to have_content("Suggest heads of terms")
    expect(page).to have_content("Heads of terms can be added for pre-applications, but no email will be sent to the applicant.")
    expect(page).to have_css("#heads-of-terms-list")
    expect(page).to have_button("Save and mark as complete")
  end

  context "with existing heads of terms" do
    let(:term_one) { create(:term, heads_of_term:, title: "Affordable housing contribution", text: "Provide a schedule of contributions") }
    let(:term_two) { create(:term, heads_of_term:, title: "Highway works", text: "Submit section 278 agreement") }

    before do
      Current.user = assessor

      term_one
      term_two
      visit current_path
    end

    it "shows existing heads of terms and edit/remove actions" do
      within("#term_#{term_one.id}") do
        expect(page).to have_content("Affordable housing contribution")
        expect(page).to have_link("Edit")
        expect(page).to have_link("Remove")
      end

      within("#term_#{term_two.id}") do
        expect(page).to have_content("Highway works")
        expect(page).to have_link("Edit")
        expect(page).to have_link("Remove")
      end

      expect(page).to have_button("Save and mark as complete")
    end
  end

  context "when a head of term exists" do
    let(:existing_term) { create(:term, heads_of_term:) }

    before do
      Current.user = assessor

      existing_term
      visit current_path
    end

    it "updates the task status when save buttons are clicked" do
      expect(task).to be_not_started

      click_button "Save changes"

      expect(page).to have_content("Head of terms have been confirmed")
      expect(task.reload).to be_in_progress

      click_button "Save and mark as complete"

      expect(page).to have_content("Head of terms have been confirmed")
      expect(task.reload).to be_completed
    end
  end

  it "redirects back to the task page after adding a head of term" do
    find("span", text: "Add a new heads of terms").click
    fill_in "Enter title", with: "Viability review mechanism"
    fill_in "Enter details", with: "Include early and late stage review clauses"
    click_button "Add term"

    expect(page).to have_content("Suggest heads of terms")
    expect(page).to have_content("Head of terms has been successfully added")

    within("#heads-of-terms-list") do
      expect(page).to have_content("Viability review mechanism")
    end
  end

  context "when editing a head of term" do
    let(:editable_term) { create(:term, heads_of_term:, title: "Original title", text: "Original details") }

    before do
      Current.user = assessor

      editable_term
      visit current_path
    end

    it "redirects back to the task page after editing a head of term" do
      within("#term_#{editable_term.id}") do
        click_link "Edit"
      end

      expect(page).to have_content("Edit heads of terms")
      fill_in "Enter title", with: "Updated title"
      fill_in "Enter details", with: "Updated details"
      click_button "Update term"

      expect(page).to have_content("Suggest heads of terms")
      expect(page).to have_content("Head of terms was successfully updated")

      within("#term_#{editable_term.id}") do
        expect(page).to have_content("Updated title")
      end
    end
  end

  context "when removing a head of term", :js do
    let(:term_one) { create(:term, heads_of_term:, title: "Remove me", text: "Detail to remove") }
    let(:term_two) { create(:term, heads_of_term:, title: "Keep me", text: "Detail to keep") }

    before do
      Current.user = assessor

      term_one
      term_two
      visit current_path
    end

    it "redirects back to the task page after removing a head of term" do
      Current.user = assessor

      within("#term_#{term_one.id}") do
        accept_confirm do
          click_link "Remove"
        end
      end

      expect(page).to have_content("Head of terms was successfully removed")
      expect(page).not_to have_content("Remove me")
      expect(page).to have_content("Keep me")
    end
  end

  it "raises an error when attempting to redirect to external URLs" do
    Current.user = assessor
    term = create(:term, heads_of_term:, title: "Existing term", text: "Existing details")

    visit "/planning_applications/#{planning_application.reference}/assessment/terms/#{term.id}/edit?redirect_to=https://phising.com/"

    fill_in "Enter title", with: "Section 106 agreement"
    fill_in "Enter details", with: "Provide updated wording"

    expect {
      click_button "Update term"
    }.to raise_error(ActionController::Redirecting::UnsafeRedirectError)
  end

  it "warns when navigating away with unsaved changes", js: true do
    find("span", text: "Add a new heads of terms").click

    fill_in "Enter title", with: "Viability review mechanism"

    dismiss_confirm(text: "You have unsaved changes") do
      within ".bops-sidebar" do
        click_link "Site and surroundings"
      end
    end

    expect(page).to have_current_path(/suggest-heads-of-terms/)
  end
end
