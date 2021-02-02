# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Edit document numbers page", type: :system do
  let(:local_authority) { create :local_authority }
  let!(:planning_application) do
    create :planning_application,
           local_authority: local_authority
  end
  let(:assessor) { create :user, :assessor, local_authority: local_authority }

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
        click_link "Validate documents"
      end

      it "Assessor can see content for the right application" do
        expect(page).to have_text(planning_application.reference)

        expect(page).to have_text("only documents with document numbers will be be listed on the decision notice")
      end

      it "Assessor can see information about the document" do
        within(all(".app-task-list__item").first) do
          click_link "Edit"
        end
        expect(page).to have_text("Side")
        expect(page).to have_text("Elevation")
        expect(page).to have_text("Proposed")
        expect(page).to have_text("proposed-floorplan.png")
      end

      it "Assessor is able to add document numbers and save them" do
        within(all(".app-task-list__item").first) do
          click_link "Edit"
        end
        fill_in "Document number(s)", with: "new_number_1, new_number_2"

        click_button "Save and return"

        within(all(".app-task-list__item").first) do
          click_link "Edit"
        end
        # the submitted values are re-presented in the form
        expect(find_field("numbers")).to have_content "new_number_1, new_number_2"

        click_link "Documents"

        within(all(".app-task-list__item").last) do
          click_link "Edit"
        end
        fill_in "Document number(s)", with: "other_new_number_1"

        click_button "Save and return"

        expect(page).to have_content("Are the documents valid?")

        choose "Yes"

        fill_in "Day", with: "03"
        fill_in "Month", with: "12"
        fill_in "Year", with: "2021"

        click_button "Save"
      end
    end
  end
end
