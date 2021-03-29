# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Documents index page", type: :system do
  let(:assessor) { create :user, :assessor, local_authority: @default_local_authority }
  let(:reviewer) { create :user, :reviewer, local_authority: @default_local_authority }

  let!(:planning_application) do
    create :planning_application,
           local_authority: @default_local_authority,
           address_1: "Elm Grove"
  end

  let(:document_tags) do
    [Document::TAGS.first, Document::TAGS.last]
  end

  let!(:document) do
    create :document, :with_file,
           planning_application: planning_application,
           tags: document_tags
  end

  let!(:not_started_planning_application) do
    create :planning_application, :not_started,
           local_authority: @default_local_authority,
           address_1: "Elm Grove"
  end

  let!(:not_started_document) do
    create :document, :with_file,
           planning_application: not_started_planning_application,
           tags: document_tags
  end

  let!(:awaiting_determination_planning_application) do
    create :planning_application, :awaiting_determination,
           local_authority: @default_local_authority,
           address_1: "Elm Grove"
  end

  let!(:awaiting_document) do
    create :document, :with_file,
           planning_application: awaiting_determination_planning_application,
           tags: document_tags
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
      expect(page).to have_text("Archive document")
    end

    it "Assessor can see table of documents on overview page" do
      expect(page).to have_css(".current-documents > li", count: 1)
    end

    it "Archive table is initially empty" do
      expect(page).to have_text "No documents archived"
      expect(page).not_to have_css(".archive-data")
    end
  end

  context "Archiving journey" do
    before do
      sign_in assessor
      visit planning_application_path(planning_application)
      click_button "Documents"
      click_link "Manage documents"
      click_link "Archive document"
    end

    it "Archive page contains site info" do
      expect(page).to have_text "Elm Grove"
    end

    it "Archive page contains application reference" do
      expect(page).to have_text planning_application.reference
    end

    it "Breadcrumbs are correct on archive page" do
      within(find(".govuk-breadcrumbs__list", match: :first)) do
        expect(page).to have_link "Application"
        expect(page).to have_link "Home"
        expect(page).to have_text "Archive document"
        expect(page).to have_no_link "Archive document"
      end
    end

    it "allows document to be archived with an optional comment" do
      fill_in "Why do you want to archive this document?", with: "Scale was wrong"
      click_button "Archive"

      click_link "Application"
      click_button "Key application dates"
      click_link "Activity log"

      expect(page).to have_text("Document archived")
      expect(page).to have_text("proposed-floorplan.png")
      expect(page).to have_text(assessor.name)
      expect(page).to have_text(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
    end

    it "User can log out from archive page" do
      click_button "Log out"

      expect(page).to have_current_path(/sign_in/)
      expect(page).to have_content("You need to sign in or sign up before continuing.")
    end

    it "Archived document appears in correct place on DMS page" do
      fill_in "Why do you want to archive this document?", with: "Scale was wrong"
      click_button "Archive"

      within(all(".archived-documents").last) do
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

  context "as a reviewer" do
    before do
      sign_in reviewer
      visit planning_application_path(planning_application)
      click_button "Documents"
      click_link "Manage documents"
      click_link "Archive document"
    end

    it "Reviewer can archive document" do
      fill_in "Why do you want to archive this document?", with: "Scale was wrong"
      click_button "Archive"

      expect(page).to have_text("proposed-floorplan.png has been archived")
    end
  end

  context "Application that has not been started" do
    before do
      sign_in assessor
      visit planning_application_path(not_started_planning_application)
      click_button "Documents"
      click_link "Manage documents"
      click_link "Archive document"
    end

    it "Document can be archived" do
      fill_in "Why do you want to archive this document?", with: "Scale was wrong"
      click_button "Archive"

      expect(page).to have_text("proposed-floorplan.png has been archived")
    end
  end

  context "Application that is awaiting determination" do
    before do
      sign_in assessor
      visit planning_application_path(awaiting_determination_planning_application)
      click_button "Documents"
      click_link "Manage documents"
    end

    it "Archive button is not visible" do
      expect(page).to have_no_link("Archive document")
    end
  end
end
