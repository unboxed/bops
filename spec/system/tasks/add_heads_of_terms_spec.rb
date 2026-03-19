# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Add heads of terms task", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:api_user) { create(:api_user, :planx, local_authority:) }
  let(:user) { create(:user, :assessor, local_authority:) }
  let(:planning_application) { create(:planning_application, :planning_permission, :in_assessment, local_authority:, api_user:, decision: "granted") }
  let(:task) { planning_application.case_record.find_task_by_slug_path!("check-and-assess/complete-assessment/add-heads-of-terms") }
  let(:heads_of_term) { planning_application.heads_of_term }

  before do
    sign_in(user)
    visit "/planning_applications/#{planning_application.reference}"
    click_link "Check and assess"
  end

  it "can add a term" do
    within :sidebar do
      click_link "Add heads of terms"
    end

    fill_in "Enter title", with: "New term"
    fill_in "Enter details", with: "Details of term"
    click_button "Save"

    expect(page).to have_content("Term was successfully added")
    expect(page).to have_content("New term")
    expect(task.reload).to be_in_progress
  end

  it "validates term fields" do
    within :sidebar do
      click_link "Add heads of terms"
    end

    click_button "Save"

    expect(page).to have_content("Enter title")
    expect(page).to have_content("Enter details for this term")
  end

  context "with existing heads of terms" do
    before { Current.user = user }

    let!(:term) { create(:term, heads_of_term:, title: "Original term title") }
    let!(:term_2) { create(:term, heads_of_term:, title: "Term 2", text: "Details about term two") }

    it "can edit and term and fields are pre-populated" do
      within :sidebar do
        click_link "Add heads of terms"
      end

      within("#heads-of-terms-list") do
        first(:link, "Edit").click
      end

      expect(page).to have_field("Enter title", with: term.title)
      expect(page).to have_field("Enter details", with: term.text)

      fill_in "Enter title", with: "Updated term title"
      fill_in "Enter details", with: "Updated term details"
      click_button "Save"

      expect(page).to have_content("Term was successfully updated")
      expect(page).to have_content("Updated term title")
      expect(page).not_to have_content("Original term title")
    end

    it "can delete a term", :capybara do
      within :sidebar do
        click_link "Add heads of terms"
      end

      terms_count = heads_of_term.terms.count

      within("#heads-of-terms-list") do
        accept_confirm do
          first(:link, "Remove").click
        end
      end

      expect(page).to have_content("Head of terms was successfully removed")
      expect(heads_of_term.terms.count).to eq(terms_count - 1)
    end
  end

  it "can mark heads of terms as complete" do
    within :sidebar do
      click_link "Add heads of terms"
    end

    click_button "Save and mark as complete"

    expect(page).to have_content("Successfully updated heads of terms")
    expect(task.reload).to be_completed
  end

  it "can save as draft" do
    within :sidebar do
      click_link "Add heads of terms"
    end

    click_button "Save changes"

    expect(page).to have_content("Successfully updated heads of terms")
    expect(task.reload).to be_in_progress
  end
end
