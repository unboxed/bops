# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Documents index page", type: :system do
  let(:local_authority) { create :local_authority }
  let(:site) { create :site, address_1: "Elm Grove" }
  let(:assessor) { create :user, :assessor, local_authority: local_authority }
  let(:reviewer) { create :user, :reviewer, local_authority: local_authority }

  let!(:planning_application) do
    create :planning_application,
           :lawfulness_certificate,
           site: site,
           local_authority: local_authority
  end

  let(:document_tags) {
    [ Document::TAGS.first, Document::TAGS.last ]
  }

  let!(:document) do
    create :document, :with_plan,
           planning_application: planning_application,
           tags: document_tags
  end

  context "as a user who is not logged in" do
    scenario "User cannot see archive page" do
      visit planning_application_documents_path(planning_application)
      expect(page).to have_current_path(/sign_in/)
      expect(page).to have_content("You need to sign in or sign up before continuing.")
    end
  end

  context "as an assessor" do
    before do
      sign_in assessor
      visit planning_application_path(planning_application)
      click_button "Proposal documents"
      click_link "Manage documents"
    end

    scenario "Assessor can see Archive document links when application is in assessment" do
      expect(page).to have_text("Archive document")
    end

    scenario "Assessor can see table of documents on overview page" do
      expect(page).to have_css(".current-documents > li", count: 1)
    end

    scenario "Archive table is initially empty" do
      expect(page).to have_text "No documents archived"
      expect(page).not_to have_css(".archive-data")
    end
  end

  context "Archiving journey" do
    before do
      sign_in assessor
      visit planning_application_path(planning_application)
      click_button "Proposal documents"
      click_link "Manage documents"
      click_link "Archive document"
    end

    scenario "Archive page contains radio buttons and image" do
      expect(page).to have_text "Missing scale bar or north arrow"
      expect(page).to have_css(".govuk-radios__item")
    end

    scenario "Archive page contains site info" do
      expect(page).to have_text "Elm Grove"
    end

    scenario "Archive page contains application reference" do
      expect(page).to have_text planning_application.reference
    end

    scenario "Breadcrumbs are correct on archive page" do
      within(find(".govuk-breadcrumbs__list", match: :first)) do
        expect(page).to have_link "Application"
        expect(page).to have_link "Home"
        expect(page).to have_text "Archive document"
        expect(page).to have_no_link "Archive document"
      end
    end

    scenario "User can log out from archive page" do
      click_button "Log out"

      expect(page).to have_current_path(/sign_in/)
      expect(page).to have_content("You need to sign in or sign up before continuing.")
    end

    scenario "Assessor can proceed to confirmation page" do
      choose "scale"
      click_button "Save"
      expect(page).to have_current_path(/validate_step/)
    end

    scenario "Correct reason is shown on confirmation page" do
      choose "scale"
      click_button "Save"
      expect(page).to have_text("Missing scale bar or north arrow")
    end

    scenario "Assessor sees error message if radio button not selected" do
      click_button "Save"

      expect(page).to have_text("Please select one of the below options")
     end

    scenario "Assessor is returned to archive page if 'No' is selected" do
      choose "scale"
      click_button "Save"
      choose "No"
      click_button "Save"

      expect(page).to have_text("Why do you want to archive this document?")
    end

    scenario "Assessor can archive a document" do
      choose "scale"
      click_button "Save"

      choose "Yes"
      click_button "Save"

      expect(page).to have_current_path(/documents/)
    end

    scenario "Assessor can archive a document and sees message" do
      choose "scale"
      click_button "Save"

      choose "Yes"
      click_button "Save"

      expect(page).to have_text("proposed-floorplan.png has been archived")
    end

    scenario "Assessor sees error message if neither Yes nor No is selected" do
      choose "scale"
      click_button "Save"
      click_button "Save"

      expect(page).to have_text("Please select one of the below options")
    end

    scenario "Archived document appears in correct place on DMS page" do
      choose "scale"
      click_button "Save"
      choose "Yes"
      click_button "Save"

      within(find(".archived-documents")) do
        expect(page).to have_text("Missing scale bar")
        expect(page).to have_text("proposed-floorplan.png")

        document_tags.each do |tag|
          expect(page).to have_css(".govuk-tag", text: tag)
        end
      end
    end

    scenario "Archived document does not appear on overview page" do
      expect(page).not_to have_css(".document-card")
    end
  end

  context "as a reviewer" do
    before do
      sign_in reviewer
      visit planning_application_path(planning_application)
      click_button "Proposal documents"
      click_link "Manage documents"
    end

    scenario "Reviewer cannot see Archive links" do
      expect(page).not_to have_link("Archive document")
    end
  end
end
