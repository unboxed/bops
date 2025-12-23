# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Review documents task", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:planning_application) { create(:planning_application, :pre_application, :not_started, local_authority:) }
  let(:task) { planning_application.case_record.find_task_by_slug_path!("check-and-validate/check-tag-and-confirm-documents/review-documents") }

  let(:user) { create(:user, local_authority:, name: "Alice Smith") }

  before do
    Rails.application.load_seed
    sign_in(user)
    visit "/planning_applications/#{planning_application.reference}/validation/tasks"
  end

  context "when there are no documents" do
    it "displays a message indicating no active documents" do
      within ".bops-sidebar" do
        click_link "Review documents"
      end

      expect(page).to have_content("There are no active documents")
    end
  end

  context "when there are documents" do
    let!(:document) { create(:document, :with_tags, planning_application:) }

    it "displays the documents in a table" do
      within ".bops-sidebar" do
        click_link "Review documents"
      end

      expect(page).to have_content("proposed-floorplan.png")
    end

    it "redirects back to the task after editing a document" do
      within ".bops-sidebar" do
        click_link "Review documents"
      end

      click_link "proposed-floorplan.png"

      expect(page).to have_content("Check supplied document")

      click_button "Save"

      expect(page).to have_current_path(%r{/check-and-validate/check-tag-and-confirm-documents/review-documents})
      expect(page).to have_content("Submitted documents")
    end
  end

  it "can complete the task" do
    within ".bops-sidebar" do
      click_link "Review documents"
    end

    click_button "Save and mark as complete"

    expect(task.reload).to be_completed
  end
end
