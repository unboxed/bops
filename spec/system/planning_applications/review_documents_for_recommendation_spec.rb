# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Review documents for recommendation" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application, :in_assessment, local_authority: default_local_authority)
  end

  let!(:document_with_reference) { create(:document, numbers: "REF222", planning_application: planning_application) }
  let!(:document_with_reference_and_tags) { create(:document, :with_tags, numbers: "REF111", planning_application: planning_application) }
  let!(:document_decision_notice) { create(:document, :referenced, planning_application: planning_application) }
  let!(:document_publishable) { create(:document, :referenced, :public, planning_application: planning_application) }
  let!(:document_without_reference) { create(:document, planning_application: planning_application) }
  let!(:document_archived) { create(:document, :archived, planning_application: planning_application) }

  %w[document_with_reference document_with_reference_and_tags document_decision_notice document_publishable].each do |type|
    let("#{type}__decision_notice_checkbox") { find_checkbox_by_id("referenced_in_decision_notice_document_#{send(type).id}") }
    let("#{type}__publishable_checkbox") { find_checkbox_by_id("publishable_document_#{send(type).id}") }
  end

  before do
    sign_in assessor
    visit planning_application_path(planning_application)
  end

  context "when planning application is in assessment" do
    it "I can view the information on the review documents for recommendation page" do
      click_link "Check and assess"

      within("#complete-assessment-tasks") do
        expect(page).to have_content("Not started")
        click_link "Review documents for recommendation"
      end

      within(".govuk-breadcrumbs__list") do
        expect(page).to have_content("Review documents")
      end

      expect(page).to have_current_path(
        planning_application_review_documents_path(planning_application)
      )

      within(".govuk-heading-l") do
        expect(page).to have_content("Review documents for recommendation")
      end
      expect(page).to have_content("Application number: #{planning_application.reference}")
      expect(page).to have_content(planning_application.full_address)
      expect(page).to have_content("#{planning_application.type_and_work_status}: #{planning_application.description}")
      expect(page).to have_content("All documents need a reference to be on the decision notice or made public")

      within(".govuk-table__head") do
        expect(page).to have_content("Documents")
        expect(page).to have_content("On decision notice")
        expect(page).to have_content("Public")
      end

      within(".govuk-button-group") do
        expect(page).to have_button("Save and mark as complete")
        expect(page).to have_button("Save and come back later")
        expect(page).to have_link("Back")
      end

      expect(page).to have_link("Manage documents", href: planning_application_documents_path(planning_application))
    end

    it "I can only view active documents on the review documents for recommendation page" do
      click_link "Check and assess"
      click_link "Review documents for recommendation"

      expect(page).not_to have_css("#document_#{document_archived.id}")

      expect(page).to have_css("#document_#{document_with_reference.id}")
      expect(page).to have_css("#document_#{document_with_reference_and_tags.id}")
      expect(page).to have_css("#document_#{document_decision_notice.id}")
      expect(page).to have_css("#document_#{document_publishable.id}")
      expect(page).to have_css("#document_#{document_without_reference.id}")
    end

    it "I can view the document reference and associated tags" do
      click_link "Check and assess"
      click_link "Review documents for recommendation"

      within("#document_#{document_with_reference.id}") do
        expect(page).to have_content(document_with_reference.numbers)
        expect(page).not_to have_content(document_with_reference.file.filename)
        expect(page).to have_content("No tags added")
      end

      within("#document_#{document_with_reference_and_tags.id}") do
        expect(page).to have_content(document_with_reference_and_tags.numbers)
        expect(page).not_to have_content(document_with_reference_and_tags.file.filename)
        expect(page).to have_content("Side Elevation Proposed Photograph")
      end

      within("#document_#{document_without_reference.id}") do
        expect(page).to have_content(document_without_reference.file.filename)
      end
    end

    it "I can edit whether documents are on the decision notice / made public and save and mark as complete" do
      click_link "Check and assess"
      click_link "Review documents for recommendation"

      within(".govuk-table__body") do
        # Check for documents that are or aren't on decision notice / public
        expect(document_with_reference__decision_notice_checkbox).not_to be_checked
        expect(document_with_reference__publishable_checkbox).not_to be_checked

        expect(document_with_reference_and_tags__decision_notice_checkbox).not_to be_checked
        expect(document_with_reference_and_tags__publishable_checkbox).not_to be_checked

        expect(document_decision_notice__decision_notice_checkbox).to be_checked
        expect(document_decision_notice__publishable_checkbox).not_to be_checked

        expect(document_publishable__decision_notice_checkbox).to be_checked
        expect(document_publishable__publishable_checkbox).to be_checked

        # Now edit a few checkboxes
        document_with_reference__decision_notice_checkbox.click
        document_with_reference_and_tags__decision_notice_checkbox.click
        document_with_reference_and_tags__publishable_checkbox.click
        document_decision_notice__decision_notice_checkbox.click
        document_publishable__publishable_checkbox.click
      end

      click_button "Save and mark as complete"
      expect(page).to have_content("Documents were successfully updated.")
      expect(planning_application.reload.review_documents_for_recommendation_status).to eq("complete")

      within("#complete-assessment-tasks") do
        expect(page).to have_content("Completed")
        click_link "Review documents for recommendation"
      end

      # Check for updated documents that are or aren't on decision notice / public
      expect(document_with_reference__decision_notice_checkbox).to be_checked
      expect(document_with_reference__publishable_checkbox).not_to be_checked
      expect(document_with_reference.reload).to have_attributes(
        referenced_in_decision_notice: true,
        publishable: false
      )

      expect(document_with_reference_and_tags__decision_notice_checkbox).to be_checked
      expect(document_with_reference_and_tags__publishable_checkbox).to be_checked
      expect(document_with_reference_and_tags.reload).to have_attributes(
        referenced_in_decision_notice: true,
        publishable: true
      )

      expect(document_decision_notice__decision_notice_checkbox).not_to be_checked
      expect(document_decision_notice__publishable_checkbox).not_to be_checked
      expect(document_decision_notice.reload).to have_attributes(
        referenced_in_decision_notice: false,
        publishable: false
      )

      expect(document_publishable__decision_notice_checkbox).to be_checked
      expect(document_publishable__publishable_checkbox).not_to be_checked
      expect(document_publishable.reload).to have_attributes(
        referenced_in_decision_notice: true,
        publishable: false
      )
    end

    it "I can edit whether documents are on the decision notice / made public and save and come back later" do
      click_link "Check and assess"
      click_link "Review documents for recommendation"

      within(".govuk-table__body") do
        document_with_reference_and_tags__decision_notice_checkbox.click
        document_with_reference_and_tags__publishable_checkbox.click
      end

      click_button "Save and come back later"
      expect(page).to have_content("Documents were successfully updated.")
      expect(planning_application.reload.review_documents_for_recommendation_status).to eq("in_progress")

      within("#complete-assessment-tasks") do
        expect(page).to have_content("In progress")
        click_link "Review documents for recommendation"
      end

      expect(document_with_reference_and_tags__decision_notice_checkbox).to be_checked
      expect(document_with_reference_and_tags__publishable_checkbox).to be_checked
    end

    it "I see a link to add a document reference when a reference hasn't been set" do
      click_link "Check and assess"
      click_link "Review documents for recommendation"

      within("#document_#{document_without_reference.id}") do
        expect(page).to have_link(
          "Add document reference",
          href: edit_planning_application_document_path(planning_application, document_without_reference)
        )
        expect(page).not_to have_css("govuk-checkboxes")
      end
    end

    context "when there is an ActiveRecord Error raised" do
      before do
        allow_any_instance_of(Document).to receive(:update!).and_raise(ActiveRecord::ActiveRecordError)
      end

      it "there is an error message and no update is persisted" do
        click_link "Check and assess"
        click_link "Review documents for recommendation"

        document_with_reference__decision_notice_checkbox.click
        document_with_reference_and_tags__decision_notice_checkbox.click

        click_button "Save and mark as complete"
        expect(page).to have_content("Couldn't update documents with error: ActiveRecord::ActiveRecordError. Please contact support.")

        expect(planning_application.review_documents_for_recommendation_status).to eq("not_started")
        expect(document_with_reference__decision_notice_checkbox).not_to be_checked
        expect(document_with_reference_and_tags__decision_notice_checkbox).not_to be_checked
      end
    end
  end

  context "when planning application has not been validated yet" do
    let!(:planning_application) do
      create(:planning_application, :not_started, local_authority: default_local_authority)
    end

    it "does not allow me to visit the page" do
      visit planning_application_review_documents_path(planning_application)

      expect(page).to have_content("forbidden")
    end
  end
end
