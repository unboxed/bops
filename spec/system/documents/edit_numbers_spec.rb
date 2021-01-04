# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Edit document numbers page", type: :system do
  let(:local_authority) { create :local_authority }
  let!(:planning_application) do
    create :planning_application,
           :lawfulness_certificate,
           local_authority: local_authority
  end
  let(:assessor) { create :user, :assessor, local_authority: local_authority }
  let(:reviewer) { create :user, :reviewer, local_authority: local_authority }

  context "as a user who is not logged in" do
    it "User cannot see edit_numbers page" do
      visit edit_numbers_planning_application_documents_path(planning_application)
      expect(page).to have_current_path(/sign_in/)
      expect(page).to have_content("You need to sign in or sign up before continuing.")
    end
  end

  context "as an assessor" do
    before do
      sign_in assessor
      visit planning_application_path(planning_application)
    end

    context "when there are no documents that require numbers" do
      it "shows a message and links to the document upload page" do
        click_link "Attach document numbers"

        expect(page).to have_content("No documents are available")
        expect(page).to have_link("upload proposal documents", href: /documents\/new/)
        expect(page).to have_link("Back", href: /planning_applications\//)
      end
    end

    context "when there are documents that require numbers" do
      let!(:proposed_tag) { Document::PROPOSED_TAGS.first }

      let!(:proposed_document_1) do
        create :document, :with_file, tags: [proposed_tag],
                                      planning_application: planning_application
      end

      let!(:proposed_document_2) do
        create :document, :with_file, tags: [proposed_tag],
                                      planning_application: planning_application
      end

      let!(:existing_document) do
        create :document, :with_file, :existing_tags,
               planning_application: planning_application
      end

      let!(:archived_document) do
        create :document, :with_file, :proposed_tags, :archived,
               planning_application: planning_application
      end

      before do
        click_link "Attach document numbers"
      end

      it "Assessor can see content for the right application" do
        expect(page).to have_text(planning_application.reference)
        expect(page).to have_text(planning_application.site.full_address)
        expect(page).to have_text("Attach document numbers")
        expect(page).to have_text("These will be published in the decision notice.")
      end

      it "Assessor can see information about the document" do
        within(all(".thumbnail").first) do
          expect(page).to have_text(proposed_tag)
          expect(page).to have_text("proposed-floorplan.png")
        end
      end

      it "Assessor is able to add document numbers and save them" do
        within(all(".thumbnail").first) do
          fill_in "numbers", with: "new_number_1, new_number_2"
        end

        click_button "Save"

        expect(page).to have_content "Attach document numbers"

        within(all(".thumbnail").first) do
          # the submitted values are re-presented in the form
          expect(find_field("numbers")).to have_content "new_number_1, new_number_2"
        end

        within(all(".thumbnail").last) do
          expect(page).to have_content("Provide at least one number")
          fill_in "numbers", with: "other_new_number_1"
        end

        click_button "Save"

        # redirected to the application assessment page
        expect(page).to have_text("Make recommendation")
        expect(page).to have_text("Updated 2 documents with numbers")
      end
    end
  end
end
