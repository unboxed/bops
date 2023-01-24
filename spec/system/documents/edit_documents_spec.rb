# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Edit document" do
  let!(:default_local_authority) { create(:local_authority, :default) }

  let!(:planning_application) do
    create(
      :planning_application,
      :not_started,
      local_authority: default_local_authority
    )
  end

  let!(:document) do
    create(:document, :with_file, planning_application: planning_application,
                                  applicant_description: "This file shows the drawing")
  end
  let(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

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

    it "displays the planning application address and reference" do
      expect(page).to have_content(planning_application.full_address)
      expect(page).to have_content(planning_application.reference)
    end

    it "archives and replaces existing document when new file is uploaded" do
      visit(
        edit_planning_application_document_path(planning_application, document)
      )

      check("Front")
      fill_in("Document reference(s)", with: "DOC123")
      click_button("Save")
      click_link("Edit")

      expect(page).to have_content("proposed-floorplan.png")
      expect(page).to have_field("Document reference(s)", with: "DOC123")
      expect(page).to have_field("Front", checked: true)

      attach_file(
        "Upload a replacement file",
        "spec/fixtures/images/proposed-roofplan.png"
      )

      click_button("Save")

      within(".archived-documents") do
        expect(page).to have_content("proposed-floorplan.png")
      end

      click_link("Edit")

      expect(page).to have_content("proposed-roofplan.png")
      expect(page).to have_field("Document reference(s)", with: "DOC123")
      expect(page).to have_field("Front", checked: true)
    end

    context "when there is an open replacement request" do
      before do
        create(
          :replacement_document_validation_request,
          old_document: document,
          planning_application: planning_application
        )
      end

      it "renders an error if user tries to replace the file" do
        visit(
          edit_planning_application_document_path(planning_application, document)
        )

        attach_file(
          "Upload a replacement file",
          "spec/fixtures/images/proposed-roofplan.png"
        )

        click_button("Save")

        expect(page).to have_content(
          "You cannot replace the file when there is an open document replacement request"
        )
      end
    end

    it "renders error when document is in unrepresentable format" do
      visit(
        edit_planning_application_document_path(planning_application, document)
      )

      attach_file(
        "Upload a replacement file",
        "spec/fixtures/files/valid_planning_application.json"
      )

      click_button("Save")

      expect(page).to have_content(
        "The selected file must be a PDF, JPG or PNG"
      )
    end

    it "with wrong format document" do
      visit edit_planning_application_document_path(planning_application, document)

      attach_file("Upload a replacement file", "spec/fixtures/images/bmp.bmp")

      click_button("Save")

      expect(page).to have_content("The selected file must be a PDF, JPG or PNG")
    end

    it "cannot validate document via manage documents screen" do
      visit edit_planning_application_document_path(planning_application, document)

      expect(page).not_to have_content("Is the document valid?")
      expect(page).not_to have_css("#validate-document")
    end

    context "when a document has been removed due to a security issue" do
      let!(:document) do
        create(:document, planning_application: planning_application)
      end

      before do
        allow_any_instance_of(Document).to receive(:representable?).and_return(false)
      end

      it "cannot edit" do
        visit edit_planning_application_document_path(planning_application, document)

        expect(page).to have_content("forbidden")
      end
    end

    context "when editing/archiving document from the documents accordian section" do
      it "can edit document and return back to the planning applications index page" do
        visit(
          edit_planning_application_document_path(
            planning_application,
            document
          )
        )

        fill_in("Document reference(s)", with: "DOCREF123")

        click_button "Save"

        expect(page).to have_content("Document has been updated")

        expect(page).to have_current_path(
          planning_application_documents_path(planning_application)
        )
      end

      it "can archive document and return back to the planning applications index page" do
        visit(
          planning_application_document_archive_path(
            planning_application,
            document
          )
        )

        fill_in "archive_reason", with: "an archive reason"

        click_button "Archive"

        expect(page).to have_content("#{document.name} has been archived")

        expect(page).to have_current_path(
          planning_application_documents_path(planning_application)
        )
      end
    end

    context "when editing/archiving document from the documents index" do
      it "can edit document and return back to the documents index page" do
        within(".current-documents") do
          click_link "Edit"
        end

        fill_in("Document reference(s)", with: "DOCREF123")

        click_button "Save"

        expect(page).to have_content("Document has been updated")
        expect(page).to have_current_path(planning_application_documents_path(planning_application))
      end

      it "can archive document and return back to the documents index page" do
        within(".current-documents") do
          click_link "Archive"
        end

        fill_in "archive_reason", with: "an archive reason"

        click_button "Archive"

        expect(page).to have_content("#{document.name} has been archived")
        expect(page).to have_current_path(planning_application_documents_path(planning_application))
      end

      it "the back button returns to the documents index page" do
        within(".current-documents") do
          click_link "Edit"
        end

        click_link "Back"
        expect(page).to have_current_path(planning_application_documents_path(planning_application))
      end
    end

    context "when visiting the edit/archive url directly" do
      it "edit returns to the documents index page" do
        visit edit_planning_application_document_path(planning_application, document)

        click_button "Save"
        expect(page).to have_current_path(planning_application_documents_path(planning_application))
      end

      it "archive returns to the documents index page" do
        visit planning_application_document_archive_path(planning_application, document)

        click_button "Archive"
        expect(page).to have_current_path(planning_application_documents_path(planning_application))
      end
    end
  end
end
