# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Document uploads", type: :system do
  let(:local_authority) { create :local_authority }
  let!(:planning_application) do
    create :planning_application,
           local_authority: local_authority
  end

  let!(:document) { create :document, planning_application: planning_application }
  let(:assessor) { create :user, :assessor, local_authority: local_authority }
  let(:reviewer) { create :user, :reviewer, local_authority: local_authority }

  context "for an assessor" do
    before { sign_in assessor }

    context "when the application is under assessment" do
      it "can upload, tag and confirm documents" do
        visit planning_application_documents_path(planning_application)

        click_link("Upload documents")

        attach_file("Upload a file", "spec/fixtures/images/proposed-roofplan.pdf")

        check("Floor")
        check("Side")

        click_button("Save")

        expect(page).to have_css("img[src*=\"proposed-roofplan.pdf\"]")

        expect(page).to have_css(".govuk-tag", text: "Floor")
        expect(page).to have_css(".govuk-tag", text: "Side")

        find(".govuk-breadcrumbs").click_link("Application")

        click_button("Proposal documents")

        within(find(".scroll-docs")) do
          expect(all("img").count).to eq 2
          expect(all("img").last["src"]).to have_content("proposed-roofplan.pdf")

          expect(page).to have_css(".govuk-tag", text: "Side")
          expect(page).to have_css(".govuk-tag", text: "Floor")
        end
      end

      it "cannot upload a document in the wrong format" do
        visit planning_application_documents_path(planning_application)

        click_link("Upload documents")

        attach_file("Upload a file", "spec/fixtures/images/bmp.bmp")

        check("Floor")

        click_button("Save")

        expect(page).to have_content("The selected file must be a PDF, JPG or PNG")
      end

      it "cannot save without a document being attached" do
        visit planning_application_documents_path(planning_application)

        click_link("Upload documents")

        check("Floor")

        click_button("Save")

        expect(page).to have_content("Please choose a file")
      end

      it "saves document if no tags are selected" do
        visit planning_application_documents_path(planning_application)

        click_link("Upload documents")

        attach_file("Upload a file", "spec/fixtures/images/proposed-roofplan.pdf")

        click_button("Save")

        expect(page).to have_content("proposed-roofplan.pdf has been uploaded")
      end
    end

    context "when the planning application has been submitted for review" do
      before { planning_application.assess! }

      it "the upload \"button\" is disabled" do
        visit planning_application_documents_path(planning_application)

        # The enabled call-to-action is a link, but to show it as disabled
        # we replace it with a button.
        expect(page).not_to have_link("Upload documents")
        expect(page).to have_button("Upload documents", disabled: true)
      end
    end
  end

  context "for a reviewer" do
    before { sign_in reviewer }

    it "no upload actions are visible at all" do
      visit planning_application_documents_path(planning_application)

      # Neither the enabled call-to-action or its disabled, button
      # equivalent are visible.
      expect(page).not_to have_link("Upload documents")
      expect(page).not_to have_button("Upload documents", disabled: true)
    end
  end
end
