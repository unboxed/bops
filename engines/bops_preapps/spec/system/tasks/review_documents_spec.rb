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
    visit "/planning_applications/#{planning_application.reference}/validation"
  end

  it "highlights the active task in the sidebar" do
    within ".bops-sidebar" do
      click_link "Review documents"
    end

    within ".bops-sidebar" do
      expect(page).to have_css(".bops-sidebar__task--active", text: "Review documents")
      expect(page).to have_css("a[aria-current='page']", text: "Review documents")
    end
  end

  it "has sidebar scroll controller attached" do
    within(".bops-sidebar") do
      click_link "Review documents"
    end

    expect(page).to have_css(".bops-sidebar[data-controller~='sidebar-scroll']")
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

    it "displays the download all documents button with correct data attributes" do
      within ".bops-sidebar" do
        click_link "Review documents"
      end

      expect(page).to have_link("Download all documents")
      expect(page).to have_css("[data-controller='download']")
      expect(page).to have_css("[data-application-reference-value='#{planning_application.reference}']")
      expect(page).to have_css("[data-download-target='documentsElement']")
      expect(page).to have_css("[data-document-url-value]")
      expect(page).to have_css("[data-document-title-value]")
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

    context "when a document has a replacement validation request" do
      let!(:replacement_request) do
        create(:replacement_document_validation_request, :pending,
          planning_application:,
          old_document: document,
          user:)
      end

      it "redirects back to the task after updating the replacement request" do
        within ".bops-sidebar" do
          click_link "Review documents"
        end

        click_link "proposed-floorplan.png"

        expect(page).to have_content("View request for a replacement document")

        click_link "Edit request"

        expect(page).to have_content("Request a replacement document")

        fill_in "List all issues with the document", with: "Updated reason"
        click_button "Update"

        expect(page).to have_current_path(%r{/check-and-validate/check-tag-and-confirm-documents/review-documents})
        expect(page).to have_content("Submitted documents")
      end

      it "redirects back to the task after deleting the replacement request", :capybara do
        within ".bops-sidebar" do
          click_link "Review documents"
        end

        click_link "proposed-floorplan.png"

        expect(page).to have_content("View request for a replacement document")

        accept_confirm(text: "Are you sure?") do
          click_link "Delete request"
        end

        expect(page).to have_current_path(%r{/check-and-validate/check-tag-and-confirm-documents/review-documents})
        expect(page).to have_content("Submitted documents")
      end
    end
  end

  it "can complete the task" do
    within ".bops-sidebar" do
      click_link "Review documents"
    end

    click_button "Save and mark as complete"

    expect(task.reload).to be_completed
  end

  context "when application is invalidated" do
    let(:planning_application) { create(:planning_application, :pre_application, :invalidated, local_authority:) }
    let!(:document) { create(:document, :with_tags, planning_application:) }
    let!(:replacement_request) do
      create(:replacement_document_validation_request, :open,
        planning_application:,
        old_document: document,
        user:)
    end

    it "redirects back to the task after cancelling the replacement request" do
      within ".bops-sidebar" do
        click_link "Review documents"
      end

      click_link "proposed-floorplan.png"

      expect(page).to have_content("View request for a replacement document")

      click_link "Cancel request"

      expect(page).to have_content("Cancel validation request")

      fill_in "Explain to the applicant why this request is being cancelled", with: "No longer needed"
      click_button "Confirm cancellation"

      expect(page).to have_current_path(%r{/check-and-validate/check-tag-and-confirm-documents/review-documents})
      expect(page).to have_content("Submitted documents")
    end
  end
end
