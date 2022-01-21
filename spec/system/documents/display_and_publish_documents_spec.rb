# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Edit document numbers page", type: :system do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:planning_application) do
    create :planning_application,
           local_authority: default_local_authority
  end
  let(:assessor) { create :user, :assessor, local_authority: default_local_authority }

  context "as an assessor" do
    before do
      sign_in assessor
      visit planning_application_path(planning_application)
    end

    context "when there are documents that require numbers" do
      let!(:tag) { Document::TAGS.first }

      let!(:proposed_document_1) do
        create :document, :with_file, :with_tags,
               planning_application: planning_application
      end

      let!(:proposed_document_2) do
        create :document, :with_file,
               planning_application: planning_application
      end

      let!(:archived_document) do
        create :document, :with_file, :archived,
               planning_application: planning_application
      end

      before do
        click_button "Documents"
        click_link "Manage documents"
      end

      it "Assessor can see content for the right application" do
        expect(page).to have_text(planning_application.reference)
      end

      it "Assessor can see information about the document" do
        within(all(".govuk-table__row").first) do
          click_link "Edit"
        end
        expect(page).to have_text("Side")
        expect(page).to have_text("Elevation")
        expect(page).to have_text("Proposed")
        expect(page).to have_text("Photograph")
        expect(page).to have_text("EVIDENCE")
        expect(page).to have_text("proposed-floorplan.png")
      end

      it "Assessor is able to add document numbers and save them" do
        within(all(".govuk-table__row").first) do
          click_link "Edit"
        end
        fill_in "Document reference(s)", with: "new_number_1, new_number_2"

        click_button "Save"

        within(all(".govuk-table__row").first) do
          click_link "Edit"
        end
        # the submitted values are re-presented in the form
        expect(find_field("numbers")).to have_content "new_number_1, new_number_2"

        click_link "Documents"

        within(all(".govuk-table__row").first) do
          click_link "Edit"
        end
        fill_in "Document reference(s)", with: "other_new_number_1"

        click_button "Save"
      end

      it "Assessor is able to add documents to decision notice without publishing" do
        within(all(".govuk-table__row").first) do
          click_link("Edit")
        end
        fill_in "Document reference(s)", with: "new_number_1, new_number_2"

        within(".display") do
          choose "Yes"
        end

        within(".publish") do
          choose "No"
        end

        click_button "Save"

        within(all(".govuk-table__row").first) do
          click_link "Edit"
        end
        # the submitted values are re-presented in the form
        expect(page).to have_field("numbers", with: "new_number_1, new_number_2")

        click_link "Documents"

        within(all(".govuk-table__row").first) do
          click_link "Edit"
        end
        fill_in "Document reference(s)", with: "other_new_number_1"

        click_button "Save"

        expect(planning_application.documents.for_display.count).to eq(1)
        expect(planning_application.documents.for_publication.count).to eq(0)
      end

      it "Assessor is able to publish documents without adding to the decision notice" do
        within(all(".govuk-table__row").first) do
          click_link "Edit"
        end
        fill_in "Document reference(s)", with: "new_number_1, new_number_2"

        within(".display") do
          choose "No"
        end

        within(".publish") do
          choose "Yes"
        end

        click_button "Save"

        expect(planning_application.documents.for_display.count).to eq(0)
        expect(planning_application.documents.for_publication.count).to eq(1)
      end

      it "Error message is shown if document referenced is true without document number" do
        within(all(".govuk-table__row").first) do
          click_link "Edit"
        end

        within(".display") do
          choose "Yes"
        end

        within(".publish") do
          choose "No"
        end

        click_button "Save"

        expect(page).to have_content "All documents listed on the decision notice must have a document number"
      end
    end
  end
end
