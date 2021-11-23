# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Edit document", type: :system do
  let!(:planning_application) do
    create :planning_application,
           local_authority: @default_local_authority
  end
  let!(:document) do
    create :document, :with_file, planning_application: planning_application,
                                  applicant_description: "This file shows the drawing"
  end
  let(:assessor) { create :user, :assessor, local_authority: @default_local_authority }

  context "as a user who is not logged in" do
    it "User cannot see edit_numbers page" do
      visit edit_planning_application_document_path(planning_application, document)
      expect(page).to have_current_path(/sign_in/)
      expect(page).to have_content("You need to sign in or sign up before continuing.")
    end
  end

  context "as an assessor" do
    before do
      sign_in assessor
      visit planning_application_documents_path(planning_application)
    end

    it "allows for the date received to be edited" do
      click_link "Edit"

      expect(page).to have_content("Date received")

      fill_in "Day", with: "19"
      fill_in "Month", with: "11"
      fill_in "Year", with: "2021"

      click_button("Save")
      expect(page).to have_content("Date received: 19 November 2021")
    end

    it "does not allow for a future date to be inserted in created_date" do
      click_link "Edit"

      fill_in "Day", with: "19"
      fill_in "Month", with: "11"
      fill_in "Year", with: "3021"

      click_button("Save")
      expect(page).to have_content("Date must be today or earlier. You cannot insert a future date.")
    end

    it "allows for a document to be marked as not valid" do
      click_link "Edit"

      within("#validate-document") do
        choose "No"
      end

      fill_in "Describe in full why the document is invalid. This will be sent to the applicant.", with: "BANANAS"

      click_button("Save")

      expect(page).to have_content("Invalid documents: 1")
      expect(page).to have_content("BANANAS")
    end

    it "requires a comment if the document is marked as not valid" do
      click_link "Edit"

      within("#validate-document") do
        choose "No"
      end

      fill_in "Describe in full why the document is invalid. This will be sent to the applicant.", with: " "
      click_button("Save")

      expect(page).to have_content("Please fill in the comment box with the reason(s) this document is not valid.")

      fill_in "Describe in full why the document is invalid. This will be sent to the applicant.",
              with: "This document is missing scales"
      click_button("Save")

      expect(page).to have_content("Invalid documents: 1")
      expect(page).to have_content("This document is missing scales")
    end

    it "audits the action when a document is marked invalid" do
      click_link "Edit"

      within("#validate-document") do
        choose "No"
      end

      fill_in "Describe in full why the document is invalid. This will be sent to the applicant.", with: "BANANAS"
      click_button("Save")

      visit planning_application_audits_path(planning_application)
      expect(page).to have_content("#{document.name} was marked as invalid")
      expect(page).to have_content("BANANAS")
    end

    it "audits the action when a document is changed from invalid to valid" do
      click_link "Edit"

      within("#validate-document") do
        choose "No"
      end

      fill_in "Describe in full why the document is invalid. This will be sent to the applicant.", with: "BANANAS"
      click_button("Save")

      click_link "Edit"

      within("#validate-document") do
        choose "Yes"
      end

      click_button("Save")
      visit planning_application_audits_path(planning_application)
      expect(page).to have_content("#{document.name} was modified from invalid to valid")
    end

    it "audits the action of editing the received_at date on a document" do
      click_link "Edit"

      fill_in "Day", with: "3"
      fill_in "Month", with: "10"
      fill_in "Year", with: "1989"
      click_button("Save")

      document.reload
      visit planning_application_audits_path(planning_application)
      expect(page).to have_content("received at date was modified to:")
      expect(page).to have_content(document.received_at.to_date.strftime("%e %B %Y").to_s)
    end

    it "with wrong format document" do
      visit edit_planning_application_document_path(planning_application, document)

      attach_file("Upload a replacement file", "spec/fixtures/images/bmp.bmp")

      click_button("Save")

      expect(page).to have_content("The selected file must be a PDF, JPG or PNG")
    end
  end
end
