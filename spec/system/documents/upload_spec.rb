# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Document uploads", type: :system do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:planning_application) do
    create :planning_application,
           local_authority: default_local_authority,
           decision: "granted"
  end

  let!(:document) { create :document, planning_application: planning_application }
  let(:assessor) { create :user, :assessor, local_authority: default_local_authority }
  let(:reviewer) { create :user, :reviewer, local_authority: default_local_authority }

  context "for an assessor" do
    before { sign_in assessor }

    context "when the application is under assessment" do
      it "cannot upload a document in the wrong format" do
        visit planning_application_documents_path(planning_application)

        click_link("Upload document")
        attach_file("Upload a file", "spec/fixtures/images/bmp.bmp")
        check("Floor")

        click_button("Save")

        expect(page).to have_content("The selected file must be a PDF, JPG or PNG")
      end

      it "cannot save without a document being attached" do
        visit planning_application_documents_path(planning_application)

        click_link("Upload document")
        check("Floor")
        click_button("Save")

        expect(page).to have_content("Please choose a file")
      end
    end

    context "when the planning application has been submitted for review" do
      before { planning_application.assess! }

      it "the upload \"button\" is disabled" do
        visit planning_application_documents_path(planning_application)

        # The enabled call-to-action is a link, but to show it as disabled
        # we replace it with a button.
        expect(page).not_to have_link("Upload document")
        expect(page).to have_button("Upload document", disabled: true)
      end
    end
  end
end
