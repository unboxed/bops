# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Edit document numbers page" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:planning_application) do
    create(:planning_application,
      local_authority: default_local_authority)
  end
  let(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  context "as an assessor" do
    before do
      sign_in assessor
    end

    context "when there are documents that require numbers" do
      let!(:tag) { Document::TAGS.first }

      let!(:proposed_document_1) do
        create(:document, :with_file, :with_tags,
          planning_application:)
      end

      let!(:proposed_document_2) do
        create(:document, :with_file,
          planning_application:)
      end

      let!(:archived_document) do
        create(:document, :with_file, :archived,
          planning_application:)
      end

      before do
        visit "/planning_applications/#{planning_application.reference}/documents"
      end

      it "displays the planning application address and reference" do
        expect(page).to have_content(planning_application.full_address)
        expect(page).to have_content(planning_application.reference)
      end

      it "Assessor can see information about the document" do
        within(all(".govuk-table__row").first) do
          click_link "Edit"
        end
        expect(page).to have_text("Drawings")
        expect(page).to have_text("Elevations - proposed")
        expect(page).to have_text("Floor plan - proposed")
        expect(page).to have_text("Evidence")
        expect(page).to have_text("Photographs - proposed")
        expect(page).to have_text("Utility bill")
        expect(page).to have_text("Supporting documents")
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
        expect(page).to have_field(
          "Document reference(s)",
          with: "new_number_1, new_number_2"
        )

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
        expect(page).to have_field(
          "Document reference(s)",
          with: "new_number_1, new_number_2"
        )

        click_link "Documents"

        within(all(".govuk-table__row").first) do
          click_link "Edit"
        end
        fill_in "Document reference(s)", with: "other_new_number_1"

        click_button "Save"

        expect(planning_application.documents.active.for_display.count).to eq(1)
        expect(planning_application.documents.active.for_publication.count).to eq(0)
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

        expect(planning_application.documents.active.for_display.count).to eq(0)
        expect(planning_application.documents.active.for_publication.count).to eq(1)
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

    context "when a document has been removed due to a security issue" do
      let!(:document) do
        create(:document, planning_application:)
      end

      before do
        allow_any_instance_of(Document).to receive(:representable?).and_return(false)

        visit "/planning_applications/#{planning_application.reference}/documents"
      end

      it "displays a placeholder image with error information" do
        expect(page).to have_content("This document has been removed due to a security issue")
        expect(page).to have_content("Error: Infected file found")
        expect(page).to have_content("File name: proposed-floorplan.png")
        expect(page).to have_content("Date received: #{document.received_at_or_created}")
      end
    end
  end
end
