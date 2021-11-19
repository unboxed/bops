# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Document uploads", type: :system do
  let!(:planning_application) do
    create :planning_application,
           local_authority: @default_local_authority,
           decision: "granted"
  end

  let!(:document) { create :document, planning_application: planning_application }
  let(:assessor) { create :user, :assessor, local_authority: @default_local_authority }
  let(:reviewer) { create :user, :reviewer, local_authority: @default_local_authority }

  context "for an assessor" do
    before { sign_in assessor }

    context "when the application is under assessment" do
      it "can upload, and tag documents" do
        visit planning_application_documents_path(planning_application)

        click_link("Upload document")

        attach_file("Upload a file", "spec/fixtures/images/proposed-roofplan.pdf")

        check("Floor")
        check("Side")
        check("Utility Bill")

        within(".display") do
          choose "Yes"
        end

        within(".publish") do
          choose "Yes"
        end

        fill_in "Document reference(s)", with: "DOC001"

        click_button("Save")

        expect(page).to have_css("img[src*=\"proposed-roofplan.pdf\"]")

        expect(page).to have_css(".govuk-tag", text: "Floor")
        expect(page).to have_css(".govuk-tag", text: "Side")
        expect(page).to have_css(".govuk-tag", text: "Utility Bill")
        expect(page).to have_css(".govuk-tag", text: "EVIDENCE")

        expect(page).to have_content("Included in decision notice: Yes")
        expect(page).to have_content("Public: Yes")

        find(".govuk-breadcrumbs").click_link("Application")

        click_button("Documents")

        within(find(".scroll-docs")) do
          expect(all("img").count).to eq 2
          expect(all("img").last["src"]).to have_content("proposed-roofplan.pdf")

          expect(page).to have_css(".govuk-tag", text: "Side")
          expect(page).to have_css(".govuk-tag", text: "Floor")
        end
      end

      it "does not make an uploaded document public or referenced by default" do
        visit planning_application_documents_path(planning_application)

        click_link("Upload document")

        attach_file("Upload a file", "spec/fixtures/images/proposed-roofplan.pdf")

        check("Floor")
        check("Side")

        fill_in "Document reference(s)", with: "DOC001"

        click_button("Save")

        expect(page).to have_css("img[src*=\"proposed-roofplan.pdf\"]")

        expect(page).to have_css(".govuk-tag", text: "Floor")
        expect(page).to have_css(".govuk-tag", text: "Side")

        expect(page).to have_content("Included in decision notice: No")
        expect(page).to have_content("Public: No")

        find(".govuk-breadcrumbs").click_link("Application")

        click_button("Documents")

        within(find(".scroll-docs")) do
          expect(all("img").count).to eq 2
          expect(all("img").last["src"]).to have_content("proposed-roofplan.pdf")

          expect(page).to have_css(".govuk-tag", text: "Side")
          expect(page).to have_css(".govuk-tag", text: "Floor")
        end
      end

      it "displays the date when uploaded and user who uploaded the document" do
        visit planning_application_documents_path(planning_application)

        click_link("Upload document")
        attach_file("Upload a file", "spec/fixtures/images/proposed-roofplan.pdf")

        fill_in "Day", with: "4"
        fill_in "Month", with: "11"
        fill_in "Year", with: "2021"

        click_button("Save")

        expect(page).to have_content("Date received: 4 November 2021")
        visit edit_planning_application_document_path(planning_application, planning_application.documents.last)
        expect(page).to have_content("This document was manually uploaded by #{assessor.name}")
      end

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

      it "saves document if no tags are selected" do
        visit planning_application_documents_path(planning_application)

        click_link("Upload document")

        attach_file("Upload a file", "spec/fixtures/images/proposed-roofplan.pdf")

        click_button("Save")

        expect(page).to have_content("proposed-roofplan.pdf has been uploaded")

        expect(page).to have_content("Included in decision notice: No")
        expect(page).to have_content("Public: No")
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
