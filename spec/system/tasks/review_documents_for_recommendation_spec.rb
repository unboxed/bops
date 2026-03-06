# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Review documents for recommendaiton", type: :system do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }
  let(:task) do
    planning_application.case_record.find_task_by_slug_path!(
      "check-and-assess/complete-assessment/review-documents-for-recommendation"
    )
  end

  let!(:planning_application) do
    create(:planning_application, :planning_permission, :in_assessment, local_authority: default_local_authority)
  end

  let!(:document_with_reference) { create(:document, numbers: "REF222", planning_application:) }
  let!(:document_with_reference_and_tags) { create(:document, :with_tags, numbers: "REF111", planning_application:) }
  let!(:document_decision_notice) { create(:document, :referenced, planning_application:) }
  let!(:document_publishable) { create(:document, :referenced, :public, planning_application:) }
  let!(:document_without_reference) { create(:document, planning_application:) }
  let!(:document_archived) { create(:document, :archived, planning_application:) }

  %w[document_with_reference document_with_reference_and_tags document_decision_notice document_publishable].each do |type|
    let("#{type}__decision_notice_checkbox") { find_checkbox_by_id("referenced_in_decision_notice_document_#{send(type).id}") }
    let("#{type}__publishable_checkbox") { find_checkbox_by_id("publishable_document_#{send(type).id}") }
  end

  before do
    sign_in assessor
    visit "/planning_applications/#{planning_application.reference}"
  end

  context "when planning application is in assessment" do
    it "I can view the information on the review documents for recommendation page" do
      click_link "Check and assess"

      within(".bops-sidebar") do
        click_link "Review documents for recommendation"
      end

      expect(page).to have_current_path(
        "/planning_applications/#{planning_application.reference}/check-and-assess/complete-assessment/review-documents-for-recommendation"
      )

      within("h1") do
        expect(page).to have_content("Review documents for recommendation")
      end
      expect(page).to have_content(planning_application.full_address)
      expect(page).to have_content(planning_application.description)
      expect(page).to have_content("Check document details")
      expect(page).to have_content("All documents need a reference to be on the decision notice and be made public.")

      within(".govuk-table__head") do
        expect(page).to have_content("Document reference")
        expect(page).to have_content("Tag")
        expect(page).to have_content("On decision notice")
        expect(page).to have_content("Publicly available")
      end
    end

    it "I can only view active documents on the review documents for recommendation page" do
      click_link "Check and assess"
      within ".bops-sidebar" do
        click_link "Review documents for recommendation"
      end

      expect(page).to have_css("#document_#{document_with_reference.id}")
      expect(page).to have_css("#document_#{document_with_reference_and_tags.id}")
      expect(page).to have_css("#document_#{document_decision_notice.id}")
      expect(page).to have_css("#document_#{document_publishable.id}")
      expect(page).to have_css("#document_#{document_without_reference.id}")
    end

    it "I can view the document reference and associated tags" do
      click_link "Check and assess"
      within ".bops-sidebar" do
        click_link "Review documents for recommendation"
      end

      within("#document_#{document_with_reference.id}") do
        expect(page).to have_content(document_with_reference.numbers)
        expect(page).not_to have_content(document_with_reference.name)
        expect(page).to have_content("No tags added")
      end

      within("#document_#{document_with_reference_and_tags.id}") do
        expect(page).to have_content(document_with_reference_and_tags.numbers)
        expect(page).not_to have_content(document_with_reference_and_tags.name)
        expect(page).to have_content("Elevations - proposed Photographs - proposed")
      end

      within("#document_#{document_without_reference.id}") do
        expect(page).to have_content(document_without_reference.name)
      end
    end

    it "I can edit whether documents are on the decision notice / made public and save and mark as complete" do
      click_link "Check and assess"
      within ".bops-sidebar" do
        click_link "Review documents for recommendation"
      end

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
      expect(page).to have_content("Successfully saved document review")
      expect(planning_application.reload.review_documents_for_recommendation_status).to eq("complete")
      expect(page).to have_selector("h3", text: "Check document details")

      expect(task.reload).to be_completed

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

      within ".bops-sidebar" do
        click_link "Review documents for recommendation"
      end

      within(".govuk-table__body") do
        document_with_reference_and_tags__decision_notice_checkbox.click
        document_with_reference_and_tags__publishable_checkbox.click
      end

      click_button "Save changes"
      expect(page).to have_content("Successfully saved document review")
      expect(planning_application.reload.review_documents_for_recommendation_status).to eq("in_progress")
      expect(page).to have_selector("h3", text: "Check document details")
      expect(task.reload).to be_in_progress

      within(".bops-sidebar") do
        click_link "Review documents for recommendation"
      end

      expect(document_with_reference_and_tags__decision_notice_checkbox).to be_checked
      expect(document_with_reference_and_tags__publishable_checkbox).to be_checked
    end

    it "I can click a document reference to edit it and be returned to the task page" do
      click_link "Check and assess"

      within ".bops-sidebar" do
        click_link "Review documents for recommendation"
      end

      task_page_path = "/planning_applications/#{planning_application.reference}/check-and-assess/complete-assessment/review-documents-for-recommendation"
      expect(page).to have_current_path(task_page_path)

      within("#document_#{document_with_reference.id}") do
        click_link document_with_reference.numbers
      end

      expect(page).to have_current_path(
        edit_planning_application_document_path(planning_application, document_with_reference),
        ignore_query: true
      )
      expect(page).to have_selector("h1", text: "Edit supplied document")

      fill_in "Drawing number", with: "REF999"

      click_button "Save"

      expect(page).to have_current_path(task_page_path)
      expect(document_with_reference.reload.numbers).to eq("REF999")
    end

    context "when a reference hasn't been set", capybara: true do
      it "shows me the link to add a reference" do
        click_link "Check and assess"

        within(".bops-sidebar") do
          click_link "Review documents for recommendation"
        end

        within("#document_#{document_without_reference.id}") do
          expect(page).to have_link(
            "Add document reference",
            href: edit_planning_application_document_path(planning_application, document_without_reference, route: "review")
          )
          expect(page).not_to have_css("govuk-checkboxes")
        end
      end
    end
  end
end
