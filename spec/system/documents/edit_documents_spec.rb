# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Edit document", type: :system do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:planning_application) do
    create :planning_application,
           local_authority: default_local_authority
  end
  let!(:document) do
    create :document, :with_file, planning_application: planning_application,
                                  applicant_description: "This file shows the drawing"
  end
  let(:assessor) { create :user, :assessor, local_authority: default_local_authority }

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
      expect(page).to have_content(planning_application.full_address.upcase)
      expect(page).to have_content(planning_application.reference)
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
        create :document, planning_application: planning_application
      end

      before do
        allow_any_instance_of(Document).to receive(:representable?).and_return(false)
      end

      it "cannot edit" do
        visit edit_planning_application_document_path(planning_application, document)

        expect(page).to have_content("forbidden")
      end
    end
  end
end
