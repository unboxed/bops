# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Requesting document changes to a planning application", type: :system do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  let(:file_path1) do
    file_fixture("images/proposed-roofplan.png")
  end

  let(:file_path2) do
    file_fixture("images/proposed-floorplan.png")
  end

  let(:file1) { Rack::Test::UploadedFile.new(file_path1, "image/png") }
  let(:file2) { Rack::Test::UploadedFile.new(file_path2, "image/png") }

  before do
    sign_in assessor
    visit "/planning_applications/#{planning_application.reference}"
  end

  context "before an application has been invalidated" do
    let!(:planning_application) do
      create(:planning_application, :not_started, local_authority: default_local_authority)
    end

    let!(:document1) do
      create(:document, file: file1, planning_application:)
    end

    let!(:document2) do
      create(:document, file: file2, planning_application:)
    end

    it "returns to task list if document is not marked as valid or invalid" do
      visit "/planning_applications/#{planning_application.reference}/documents/#{document1.id}/edit?validate=yes"

      click_button("Save")

      expect(page).to have_current_path(
        "/planning_applications/#{planning_application.reference}/supply_documents"
      )
    end

    it "I can mark documents as invalid and edit/delete the validation request", :capybara do
      click_link "Check and validate"
      click_link "Review documents"

      within("#check-tag-documents-tasks") do
        within("table tbody tr:nth-child(1)") do
          expect(page).to have_text("proposed-roofplan.png")
          expect(page).to have_text("Not started")
        end
        within("table tbody tr:nth-child(2)") do
          expect(page).to have_text("proposed-floorplan.png")
          expect(page).to have_text("Not started")
        end

        click_link("proposed-roofplan.png")
      end

      expect(page).not_to have_content("Upload a replacement file")
      expect(page).not_to have_css("#received-at")

      within("#validate-document") { choose "No" }
      click_button "Save"

      expect(page).to have_content("Request a replacement document")
      within("#document-summary") do
        expect(page).to have_content("This document has been marked as invalid")
        expect(page).to have_content(document1.received_at_or_created)
        expect(page).to have_content(document1.name.to_s)
      end
      expect(page).to have_content(
        "This request will be added to the application. The requests will not be sent until the application is marked as invalid."
      )
      expect(page).to have_link(
        "Applicants will be able to see this advice about how to prepare plans (opens in new tab)",
        href: public_planning_guides_path
      )
      expect(page).to have_link("Back")

      # Reason must be present
      click_button "Save request"
      within(".govuk-error-summary") do
        expect(page).to have_content("There is a problem")
        expect(page).to have_content("Provide a reason for changes")
      end

      fill_in "List all issues with the document", with: "This is very invalid"
      click_button "Save request"

      expect(page).to have_content("Replacement document validation request successfully created.")
      click_link("Validation tasks")

      document1.reload
      expect(document1.replacement_document_validation_request).to eq(ReplacementDocumentValidationRequest.last)
      expect(document1.replacement_document_validation_request.post_validation).to be_falsey

      within("#invalid-items-count") do
        expect(page).to have_content("Invalid items 1")
      end

      click_link "Review documents"

      within("#check-tag-documents-tasks") do
        within("table tbody tr:nth-child(1)") do
          expect(page).to have_text("proposed-roofplan.png")
          expect(page).to have_text("Invalid")
        end
        within("table tbody tr:nth-child(2)") do
          expect(page).to have_text("proposed-floorplan.png")
          expect(page).to have_text("Not started")
        end

        click_link("proposed-roofplan.png")
      end

      # View show page
      expect(page).to have_content("View request for a replacement document")
      within("#replacement-document-details") do
        expect(page).to have_content("Replacement for: #{document1.name}")
        expect(page).to have_content("This is very invalid")
        expect(page).to have_content(document1.replacement_document_validation_request.created_at.to_fs)
      end
      expect(page).to have_link("Back")

      # Edit the request
      click_link "Edit request"
      fill_in "List all issues with the document", with: "Not valid at all"
      click_button "Update request"
      expect(page).to have_content("Replacement document request successfully updated")

      click_link "Application"
      within "#documents-content" do
        expect(page).to have_content "Cancel replacement request"
      end
      click_link "Check and validate"

      click_link "Review documents"

      # Delete the request
      within("#check-tag-documents-tasks") do
        within("table tbody tr:nth-child(1)") do
          expect(page).to have_text("proposed-roofplan.png")
          expect(page).to have_text("Invalid")
        end

        click_link("proposed-roofplan.png")
      end
      accept_confirm(text: "Are you sure?") do
        click_link("Delete request")
      end
      expect(page).to have_content("Replacement document request successfully deleted")
      within("#invalid-items-count") do
        expect(page).to have_content("Invalid items 0")
      end

      # The document returns to "Not checked yet"
      expect(document1.reload.replacement_document_validation_request).to be_nil
      expect(document1.invalidated_document_reason).to be_nil
      expect(document1.validated).to be_nil

      click_link "Review documents"
      within("#check-tag-documents-tasks") do
        within("table tbody tr:nth-child(1)") do
          expect(page).to have_text("proposed-roofplan.png")
          expect(page).to have_text("Checked")
        end

        click_link("proposed-roofplan.png")
      end

      # Mark same document as invalid again
      within("#validate-document") { choose "No" }
      click_button "Save"

      fill_in "List all issues with the document", with: "Invalid doc"
      click_button "Save request"
      expect(page).to have_content("Replacement document validation request successfully created.")
      click_link("Validation tasks")
      expect(document1.reload.replacement_document_validation_request).to eq(ReplacementDocumentValidationRequest.last)
      within("#invalid-items-count") do
        expect(page).to have_content("Invalid items 1")
      end

      click_link "Review documents"
      within("#check-tag-documents-tasks") do
        within("table tbody tr:nth-child(1)") do
          expect(page).to have_text("proposed-roofplan.png")
          expect(page).to have_text("Invalid")
        end
      end

      click_link "Back"

      within("#review-tasks") do
        click_link "Send validation decision"
      end
      expect(page).to have_content("You have marked items as invalid, so you cannot validate this application.")
    end

    it "I can mark documents as valid" do
      click_link "Check and validate"
      click_link "Review documents"

      within("#check-tag-documents-tasks") do
        click_link("proposed-roofplan.png")
      end

      click_link "Supporting documents"
      click_link "Show all (74)"

      check "Sustainability statement"

      # Mark document as valid
      within("#validate-document") { choose "Yes" }
      click_button "Save"

      click_link "Back"
      click_link "Back"
      expect(page).to have_content "Sustainability statement"

      click_link "Check and validate"
      click_link "Review documents"
      within("#check-tag-documents-tasks") do
        within("table tbody tr:nth-child(1)") do
          expect(page).to have_text("proposed-roofplan.png")
          expect(page).to have_text("Checked")
        end
        within("table tbody tr:nth-child(2)") do
          expect(page).to have_text("proposed-floorplan.png")
          expect(page).to have_text("Not started")
        end
      end

      click_link "Back"

      click_link "Send validation decision"
      expect(page).to have_content("The application has not been marked as valid or invalid yet.")
      expect(page).to have_content("When all parts of the application have been checked and are correct, mark the application as valid.")
      expect(page).to have_link("Mark the application as valid")
    end
  end

  context "when an application has been invalidated" do
    let!(:planning_application) do
      create(:planning_application, :invalidated, local_authority: default_local_authority)
    end

    let!(:document1) do
      create(:document, file: file1, planning_application:)
    end

    let!(:document2) do
      create(:document, file: file2, planning_application:)
    end

    it "I can mark documents as invalid and cancel the validation request" do
      delivered_emails = ActionMailer::Base.deliveries.count

      click_link "Check and validate"
      click_link "Review documents"

      within("#check-tag-documents-tasks") do
        within("table tbody tr:nth-child(1)") do
          expect(page).to have_text("proposed-roofplan.png")
          expect(page).to have_text("Not started")
        end
        within("table tbody tr:nth-child(2)") do
          expect(page).to have_text("proposed-floorplan.png")
          expect(page).to have_text("Not started")
        end

        click_link("proposed-roofplan.png")
      end

      within("#validate-document") { choose "No" }
      click_button "Save"

      expect(page).to have_content("Request a replacement document")
      expect(page).to have_content("This request will be sent to the applicant immediately.")
      expect(page).to have_link(
        "Applicants will be able to see this advice about how to prepare plans (opens in new tab)",
        href: public_planning_guides_path
      )

      fill_in "List all issues with the document", with: "Not readable"
      click_button "Send request"
      expect(page).to have_content("Replacement document validation request successfully created.")
      click_link("Validation tasks")
      within("#invalid-items-count") do
        expect(page).to have_content("Invalid items 1")
      end

      click_link "Review documents"
      within("#check-tag-documents-tasks") do
        within("table tbody tr:nth-child(1)") do
          expect(page).to have_text("proposed-roofplan.png")
          expect(page).to have_text("Invalid")
        end
        within("table tbody tr:nth-child(2)") do
          expect(page).to have_text("proposed-floorplan.png")
          expect(page).to have_text("Not started")
        end
      end

      click_link "Back"

      click_link "Send validation decision"
      expect(page).to have_content("This application has 1 unresolved validation request and 0 resolved validation requests")

      click_link "Application"
      find("#audit-log").click
      click_link "View all audits"

      within("#audit_#{Audit.last.id}") do
        expect(page).to have_content("Sent: validation request (replacement document#1)")
        expect(page).to have_content(assessor.name)
        expect(page).to have_content(document1.name.to_s)
        expect(page).to have_content("Reason: Not readable")
        expect(page).to have_content(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
      end
      expect(ActionMailer::Base.deliveries.count).to eql(delivered_emails + 1)

      # Cancel request
      visit "/planning_applications/#{planning_application.reference}/validation/tasks"

      click_link "Review documents"
      within("#check-tag-documents-tasks") do
        click_link("proposed-roofplan.png")
      end

      within("#replacement-document-details") do
        expect(page).to have_content("Replacement for: #{document1.name}")
        expect(page).to have_content("Not readable")
        expect(page).to have_content(document1.replacement_document_validation_request.created_at.to_fs)
      end
      expect(page).not_to have_link("Edit request")
      expect(page).not_to have_link("Delete request")

      click_link "Cancel request"
      fill_in "Explain to the applicant why this request is being cancelled", with: "mistake"
      click_button "Confirm cancellation"
      expect(page).to have_content("Replacement document validation request successfully cancelled.")
      expect(document1.reload.replacement_document_validation_request).to be_nil
      expect(document1.invalidated_document_reason).to be_nil
      expect(document1.validated).to be_nil

      click_link "Application"
      find("#audit-log").click
      click_link "View all audits"

      within("#audit_#{Audit.last.id}") do
        expect(page).to have_content("Cancelled: validation request (replace document#1)")
        expect(page).to have_content(assessor.name)
        expect(page).to have_content("Reason: mistake")
        expect(page).to have_content(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
      end
      expect(ActionMailer::Base.deliveries.count).to eql(delivered_emails + 2)

      visit "/planning_applications/#{planning_application.reference}/validation/tasks"
      within("#invalid-items-count") do
        expect(page).to have_content("Invalid items 0")
      end
      expect(page).not_to have_content("Invalid documents")

      click_link "Review documents"
      within("#check-tag-documents-tasks") do
        within("table tbody tr:nth-child(1)") do
          expect(page).to have_text("proposed-roofplan.png")
          expect(page).to have_text("Checked")
        end
      end

      click_link "Back"

      click_link "Send validation decision"
      expect(page).to have_content("This application has 0 unresolved validation requests and 0 resolved validation requests")
    end

    context "when an applicant has responded" do
      let!(:replacement_document_validation_request) do
        create(:replacement_document_validation_request, :closed,
          planning_application:, old_document: document1)
      end

      let!(:document_response) do
        create(
          :document,
          file: file1,
          owner: replacement_document_validation_request,
          planning_application:
        )
      end

      before do
        # When new document is sent by the applicant the original document is archived
        replacement_document_validation_request.old_document.archive("replaced by new document")
      end

      it "can only view response and original document is archived" do
        # Can only view request
        visit "/planning_applications/#{planning_application.reference}/validation/replacement_document_validation_requests/#{replacement_document_validation_request.id}"
        expect(page).not_to have_link("Cancel request")
        expect(page).not_to have_link("Delete request")
        expect(page).not_to have_link("Edit request")

        expect(page).to have_content("A replacement document has been provided for this request:")
        expect(page).to have_link(
          replacement_document_validation_request.reload.new_document.name.to_s,
          href: "/planning_applications/#{planning_application.reference}/documents/#{replacement_document_validation_request.new_document.id}/edit?validate=yes"
        )

        visit "/planning_applications/#{planning_application.reference}/validation/tasks"

        within("#invalid-items-count") do
          expect(page).to have_content("Invalid items 0")
        end
        within("#updated-items-count") do
          expect(page).to have_content("Updated items 0")
        end

        click_link "Review documents"

        within("#check-tag-documents-tasks") do
          within("table tbody tr:nth-child(2)") do
            expect(page).to have_text("proposed-roofplan.png")
            expect(page).to have_text("Updated")
          end

          click_link("proposed-roofplan.png")
        end

        within("#validate-document") { choose "No" }
        click_button "Save"

        fill_in "List all issues with the document", with: "Not valid"
        click_button "Send request"
        expect(page).to have_content("Replacement document validation request successfully created.")
        click_link("Validation tasks")

        within("#invalid-items-count") do
          expect(page).to have_content("Invalid items 1")
        end

        click_link "Review documents"

        within("#check-tag-documents-tasks") do
          within("table tbody tr:nth-child(2)") do
            expect(page).to have_text("proposed-roofplan.png")
            expect(page).to have_text("Invalid")
          end
        end

        request = ReplacementDocumentValidationRequest.last
        expect(document_response.replacement_document_validation_request).to eq(request)
        expect(request.old_document).to eq(document_response)
        expect(request.new_document).to be_nil

        click_link "Back"

        click_link "Review validation requests"

        within("#replacement_document_validation_request_#{request.id}") do
          expect(page).to have_content("Replacement document")
          expect(page).to have_content("sent")
          expect(page).to have_link(
            "View and update",
            href: planning_application_validation_validation_request_path(planning_application, request)
          )
        end
        within("#replacement_document_validation_request_#{replacement_document_validation_request.id}") do
          expect(page).to have_content("Replacement document")
          expect(page).to have_content("Responded")
        end

        click_link "Back"
        click_link "Send validation decision"

        expect(page).to have_content("This application has 1 unresolved validation request and 1 resolved validation request")
      end

      it "can see reason why a replacement document was requested once the request is complete" do
        click_link "Check and validate"
        click_link "Review documents"
        click_link replacement_document_validation_request.reload.new_document.name.to_s.truncate(50).to_s

        expect(page).to have_content("This document replaced: #{replacement_document_validation_request.old_document.name}")
        expect(page).to have_link(
          replacement_document_validation_request.old_document.name.to_s,
          href: edit_planning_application_document_path(planning_application, replacement_document_validation_request.old_document)
        )
        expect(page).to have_content("Reason this replacement document was requested: Document is invalid")
        expect(page).to have_content("Applicant accepted request and uploaded this document.")
      end
    end
  end

  context "when an application has been validated" do
    let!(:planning_application) do
      create(:planning_application, :in_assessment, local_authority: default_local_authority)
    end
    let!(:document1) { create(:document, :with_file, planning_application:) }

    it "allows new replacement requests" do
      click_link "Check and assess"
      find("span", text: "Documents").click
      click_link "Request replacement"

      fill_in "List all issues with the document", with: "This is very invalid"
      click_button "Send request"

      expect(page).to have_content("Replacement document validation request successfully created.")

      document1.reload
      expect(document1.replacement_document_validation_request).to eq(ReplacementDocumentValidationRequest.last)
      expect(document1.replacement_document_validation_request.post_validation).to be true
    end

    it "appears in the post validation requests table" do
      click_link "Check and assess"
      find("span", text: "Documents").click
      click_link "Request replacement"

      fill_in "List all issues with the document", with: "This is very invalid"
      click_button "Send request"

      visit "/planning_applications/#{planning_application.reference}/validation/validation_requests/post_validation_requests"

      within ".validation-requests-table" do
        expect(page).to have_content(document1.name)
      end
    end

    it "sends an email notification" do
      delivered_emails = ActionMailer::Base.deliveries.count

      click_link "Check and assess"
      find("span", text: "Documents").click
      click_link "Request replacement"

      fill_in "List all issues with the document", with: "This is very invalid"
      click_button "Send request"

      expect(ActionMailer::Base.deliveries.count).to eql(delivered_emails + 1)
    end

    it "allows new replacement requests to be responded to" do
      click_link "Check and assess"
      find("span", text: "Documents").click
      click_link "Request replacement"

      fill_in "List all issues with the document", with: "This is very invalid"
      click_button "Send request"

      expect(page).to have_content("Replacement document validation request successfully created.")
      document1.reload

      document2 = create(:document, :with_file, planning_application:)
      request = planning_application.replacement_document_validation_requests.last
      request.new_document = document2
      request.state = "closed"
      request.save!
      request.old_document.archive("replaced by new document")

      find("span", text: "Documents").click
      click_link "Manage documents"

      within(".current-documents") do
        expect(page).to have_content("File name: #{request.new_document.name}")
      end
      within(".archived-documents") do
        expect(page).to have_content(request.old_document.name)
        expect(page).to have_content("replaced by new document")
      end
    end
  end

  context "when document is archived" do
    let!(:planning_application) do
      create(:planning_application, :invalidated, local_authority: default_local_authority)
    end

    let!(:document1) { create(:document, planning_application:, archived_at: 2.days.ago) }
    let!(:document2) { create(:document, planning_application:) }

    it "does not appear in the validate document list" do
      click_link "Check and validate"
      click_link "Review documents"

      within("#check-tag-documents-tasks") do
        within("table tbody tr:nth-child(1)") do
          expect(page).to have_text("proposed-floorplan.png")
          expect(page).to have_text("Not started")
        end

        expect(page).not_to have_content(
          "proposed-roofplan.png"
        )
      end
    end
  end

  context "when there are invalid documents" do
    let!(:planning_application) do
      create(:planning_application, :invalidated, local_authority: default_local_authority)
    end
    let!(:document) { create(:document, planning_application:, validated: false) }

    context "when there is an open or pending replacement document validation request" do
      let!(:replacement_document_validation_request) do
        create(:replacement_document_validation_request, :open, planning_application:, old_document: document)
      end

      it "does show a invalid documents warning" do
        visit "/planning_applications/#{planning_application.reference}/documents"
        expect(page).to have_content("Invalid documents: 1")
      end
    end

    context "when there is a cancelled replacement document validation request" do
      let!(:replacement_document_validation_request) do
        create(:replacement_document_validation_request, :cancelled, planning_application:, old_document: document)
      end

      it "does not show a warning" do
        visit "/planning_applications/#{planning_application.reference}/documents"
        expect(page).not_to have_content("Invalid documents")
      end
    end

    context "when there is no replacement document validation request" do
      it "does not show a warning" do
        visit "/planning_applications/#{planning_application.reference}/documents"
        expect(page).not_to have_content("Invalid documents")
      end
    end

    context "when document is archived" do
      let!(:document) { create(:document, planning_application:, validated: false, archived_at: Time.zone.now) }
      let!(:replacement_document_validation_request) do
        create(:replacement_document_validation_request, planning_application:, old_document: document)
      end

      it "does not show a warning" do
        visit "/planning_applications/#{planning_application.reference}/documents"
        expect(page).not_to have_content("Invalid documents")
      end
    end
  end

  context "when invalidation updates replacement document validates request" do
    let!(:planning_application) do
      create(:planning_application, :not_started, local_authority: default_local_authority)
    end
    let!(:replacement_document_validation_request) do
      create(:replacement_document_validation_request, planning_application:,
        state: "pending", created_at: 12.days.ago)
    end

    it "updates the notified_at date of an open request when application is invalidated" do
      click_link "Check and validate"
      click_link "Send validation decision"
      expect(replacement_document_validation_request.notified_at).to be_nil

      click_button "Mark the application as invalid"

      expect(page).to have_content("Application has been invalidated")

      planning_application.reload
      expect(planning_application.status).to eq("invalidated")

      replacement_document_validation_request.reload
      expect(replacement_document_validation_request.notified_at).to be_a Time
    end
  end
end
