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

    it "with wrong format document" do
      visit edit_planning_application_document_path(planning_application, document)

      attach_file("Upload a replacement file", "spec/fixtures/images/bmp.bmp")

      click_button("Save")

      expect(page).to have_content("The selected file must be a PDF, JPG or PNG")
    end
  end
end
