# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Upload redacted documents task", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user, local_authority:) }
  let(:task) { planning_application.case_record.find_task_by_slug_path!("check-and-validate/check-tag-and-confirm-documents/upload-redacted-documents") }

  let(:file1) { fixture_file_upload("documents/existing-floorplan.png", "image/png", true) }
  let(:file2) { fixture_file_upload("documents/proposed-floorplan.png", "image/png", true) }
  let(:file3) { fixture_file_upload("documents/archived-floorplan.png", "image/png", true) }

  before do
    sign_in(user)
  end

  %i[planning_permission prior_approval lawfulness_certificate].each do |application_type|
    context "for a #{application_type.to_s.humanize.downcase} case" do
      let(:planning_application) do
        create(:planning_application, application_type, :not_started, local_authority:)
      end

      before do
        create(:document, :floorplan_tags, file: file1, planning_application:)
        create(:document, file: file2, planning_application:)
        create(:document, :archived, file: file3, planning_application:)
        visit "/planning_applications/#{planning_application.reference}/validation"
      end

      it "shows the task in the sidebar" do
        within :sidebar do
          expect(page).to have_link("Upload redacted documents")
        end
      end

      it "navigates to the task from the sidebar" do
        within :sidebar do
          click_link "Upload redacted documents"
        end

        expect(page).to have_current_path(
          "/planning_applications/#{planning_application.reference}/check-and-validate/check-tag-and-confirm-documents/upload-redacted-documents"
        )
        expect(page).to have_content("Upload redacted documents")
      end

      it "displays non-redacted, non-archived documents for upload" do
        within :sidebar do
          click_link "Upload redacted documents"
        end

        expect(page).to have_content("existing-floorplan.png")
        expect(page).to have_content("proposed-floorplan.png")
        expect(page).not_to have_content("archived-floorplan.png")
      end

      it "displays instructions when no redacted documents exist" do
        within :sidebar do
          click_link "Upload redacted documents"
        end

        expect(page).to have_content("To add a redacted document")
        expect(page).to have_content("What you need to redact")
      end

      it "uploads a redacted document and saves as draft" do
        within :sidebar do
          click_link "Upload redacted documents"
        end

        within(all(".govuk-table__row")[1]) do
          attach_file("Upload a file", "spec/fixtures/files/documents/existing-floorplan-redacted.png")
        end

        click_button "Save changes"

        expect(page).to have_content("Redacted documents successfully uploaded")
        expect(task.reload).to be_in_progress
      end

      it "uploads a redacted document and marks as complete" do
        within :sidebar do
          click_link "Upload redacted documents"
        end

        within(all(".govuk-table__row")[1]) do
          attach_file("Upload a file", "spec/fixtures/files/documents/existing-floorplan-redacted.png")
        end

        click_button "Save and mark as complete"

        expect(page).to have_content("Redacted documents successfully uploaded")
        expect(task.reload).to be_completed
      end

      it "marks the redacted document with correct attributes" do
        within :sidebar do
          click_link "Upload redacted documents"
        end

        within(all(".govuk-table__row")[1]) do
          attach_file("Upload a file", "spec/fixtures/files/documents/existing-floorplan-redacted.png")
        end

        click_button "Save and mark as complete"

        redacted_doc = planning_application.documents.active.redacted.last
        expect(redacted_doc).to be_publishable
        expect(redacted_doc).to be_validated
        expect(redacted_doc.tags).to include("roofPlan.existing", "roofPlan.proposed")
      end

      it "shows already-redacted documents after uploading" do
        within :sidebar do
          click_link "Upload redacted documents"
        end

        within(all(".govuk-table__row")[1]) do
          attach_file("Upload a file", "spec/fixtures/files/documents/existing-floorplan-redacted.png")
        end

        click_button "Save changes"

        within :sidebar do
          click_link "Upload redacted documents"
        end

        expect(page).to have_content("existing-floorplan-redacted.png")
        expect(page).to have_content("Redact and upload another document")
      end

      it "marks as complete without uploading any files" do
        within :sidebar do
          click_link "Upload redacted documents"
        end

        click_button "Save and mark as complete"

        expect(page).to have_content("Redacted documents successfully uploaded")
        expect(task.reload).to be_completed
      end

      it "allows editing after completion" do
        task.complete!

        within :sidebar do
          click_link "Upload redacted documents"
        end

        click_button "Edit"

        expect(task.reload).to be_in_progress
      end
    end
  end

  context "when application is a pre_application" do
    let(:planning_application) { create(:planning_application, :pre_application, :not_started, local_authority:) }

    it "does not have the upload redacted documents task" do
      task = planning_application.case_record.find_task_by_slug_path("check-and-validate/check-tag-and-confirm-documents/upload-redacted-documents")
      expect(task).to be_nil
    end
  end
end
