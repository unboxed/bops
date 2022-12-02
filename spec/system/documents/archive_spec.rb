# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Documents index page" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }
  let(:reviewer) { create(:user, :reviewer, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application,
           local_authority: default_local_authority,
           address_1: "Elm Grove")
  end

  let(:document_tags) do
    [Document::TAGS.first, Document::TAGS.last]
  end

  let!(:document) do
    create(:document, :with_file,
           planning_application: planning_application,
           tags: document_tags)
  end

  let!(:not_started_planning_application) do
    create(:planning_application, :not_started,
           local_authority: default_local_authority,
           address_1: "Elm Grove")
  end

  let!(:not_started_document) do
    create(:document, :with_file,
           planning_application: not_started_planning_application,
           tags: document_tags)
  end

  let!(:awaiting_determination_planning_application) do
    create(:planning_application, :awaiting_determination,
           local_authority: default_local_authority,
           address_1: "Elm Grove")
  end

  let!(:awaiting_document) do
    create(:document, :with_file,
           planning_application: awaiting_determination_planning_application,
           tags: document_tags)
  end

  context "as a user who is not logged in" do
    it "User cannot see archive page" do
      visit planning_application_documents_path(planning_application)
      expect(page).to have_current_path(/sign_in/)
      expect(page).to have_content("You need to sign in or sign up before continuing.")
    end
  end

  context "as an assessor" do
    before do
      sign_in assessor
      visit planning_application_path(planning_application)
      click_button "Documents"
      click_link "Manage documents"
    end

    it "Assessor can see Archive document links when application is in assessment" do
      expect(page).to have_text("Archive")
    end

    it "Assessor can see table of documents on overview page" do
      within(".current-documents") do
        expect(page).to have_css("tr", count: 1)
      end
    end

    it "Archive table is initially empty" do
      expect(page).to have_text "No documents archived"
      expect(page).not_to have_css(".archive-data")
    end
  end

  context "when archiving journey" do
    before do
      sign_in assessor
      visit planning_application_path(planning_application)
      click_button "Documents"
      click_link "Manage documents"
      click_link "Archive"
    end

    it "Archive page contains site info" do
      expect(page).to have_text planning_application.full_address.upcase
    end

    it "Archive page contains application reference" do
      expect(page).to have_text planning_application.reference
    end

    it "Breadcrumbs are correct on archive page" do
      within(find(".govuk-breadcrumbs__list", match: :first)) do
        expect(page).to have_link "Application"
        expect(page).to have_link "Home"
        expect(page).to have_text "Archive"
        expect(page).not_to have_link "Archive"
      end
    end

    it "allows document to be archived with an optional comment" do
      fill_in "Why do you want to archive this document?", with: "Scale was wrong"
      click_button "Archive"

      click_link "Application"
      click_button "Audit log"
      click_link "View all audits"

      expect(page).to have_text("Document archived")
      expect(page).to have_text("proposed-floorplan.png")
      expect(page).to have_text(assessor.name)
      expect(page).to have_text(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
    end

    it "Archived document appears in correct place on DMS page" do
      fill_in "Why do you want to archive this document?", with: "Scale was wrong"
      click_button "Archive"

      within(".archived-documents") do
        expect(page).to have_text("Scale was wrong")
        expect(page).to have_text("proposed-floorplan.png")

        document_tags.each do |tag|
          expect(page).to have_css(".govuk-tag", text: tag)
        end
      end
    end

    it "Archived document does not appear on overview page" do
      expect(page).not_to have_css(".document-card")
    end
  end

  context "when restoring from archive" do
    it "Archived document can be restored" do
      sign_in assessor
      visit planning_application_path(planning_application)
      click_button "Documents"
      click_link "Manage documents"
      click_link "Archive"

      fill_in "Why do you want to archive this document?", with: "Scale was wrong"
      click_button "Archive"

      within(".archived-documents") do
        expect(page).to have_text("Scale was wrong")
        expect(page).to have_text("proposed-floorplan.png")
      end

      click_button "Restore document"

      expect(page).to have_text("proposed-floorplan.png has been restored")
      expect(page).to have_text("No documents archived")

      within(".current-documents") do
        expect(page).to have_text("proposed-floorplan.png")
      end

      click_link "Application"
      click_button "Audit log"
      click_link "View all audits"

      expect(page).to have_text("Document unarchived")
    end
  end

  context "as a reviewer" do
    before do
      sign_in reviewer
      visit planning_application_path(planning_application)
      click_button "Documents"
      click_link "Manage documents"
      click_link "Archive"
    end

    it "Reviewer can archive document" do
      fill_in "Why do you want to archive this document?", with: "Scale was wrong"
      click_button "Archive"

      expect(page).to have_text("proposed-floorplan.png has been archived")
    end
  end

  context "with an application that has not been started" do
    before do
      sign_in assessor
      visit planning_application_path(not_started_planning_application)
      click_button "Documents"
      click_link "Manage documents"
      click_link "Archive"
    end

    it "Document can be archived" do
      fill_in "Why do you want to archive this document?", with: "Scale was wrong"
      click_button "Archive"

      expect(page).to have_text("proposed-floorplan.png has been archived")
    end

    it "User can cancel archiving journey" do
      click_link "Cancel"

      expect(page).to have_current_path(/documents/)
      expect(page).to have_content("Check all documents to ensure they support the information")
    end
  end

  context "with an application that is awaiting determination" do
    before do
      sign_in assessor
      visit planning_application_path(awaiting_determination_planning_application)
      click_button "Documents"
      click_link "Manage documents"
    end

    it "Archive button is not visible" do
      expect(page).not_to have_link("Archive")
    end
  end

  context "with an associated replacement document validation request" do
    let!(:replacement_document_validation_request) do
      create(:replacement_document_validation_request, planning_application: not_started_planning_application,
                                                       old_document: not_started_document)
    end

    before do
      sign_in assessor
      visit planning_application_document_archive_path(not_started_planning_application, not_started_document)
    end

    it "I am unable to archive the document" do
      click_button "Archive"

      expect(page).to have_content("Cannot archive document with an open or pending validation request")
    end
  end

  context "when a document has been removed due to a security issue" do
    let!(:document) do
      create(:document, planning_application: planning_application)
    end

    before do
      sign_in assessor
      allow_any_instance_of(Document).to receive(:representable?).and_return(false)
    end

    it "cannot archive" do
      visit edit_planning_application_document_path(planning_application, document)

      expect(page).to have_content("forbidden")
    end
  end
end
