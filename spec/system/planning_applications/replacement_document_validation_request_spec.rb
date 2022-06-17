# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Requesting document changes to a planning application", type: :system do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  before do
    travel_to Time.zone.local(2021, 1, 1)
    sign_in assessor
    visit planning_application_path(planning_application)
  end

  context "before an application has been invalidated" do
    let!(:planning_application) do
      create :planning_application, :not_started, local_authority: default_local_authority
    end
    let!(:document1) { create(:document, :with_file, planning_application: planning_application) }
    let!(:document2) { create(:document, :with_file, planning_application: planning_application) }

    it "returns to task list if document is not marked as valid or invalid" do
      visit(
        edit_planning_application_document_path(
          planning_application,
          document1,
          validate: "yes"
        )
      )

      click_button("Save")

      expect(page).to have_current_path(
        planning_application_validation_tasks_path(planning_application)
      )
    end

    it "I can mark documents as invalid and edit/delete the validation request" do
      click_link "Check and validate"

      within("#document-validation-tasks") do
        within("#document_#{document2.id}") do
          expect(page).to have_content("Not checked yet")
        end
        within("#document_#{document1.id}") do
          expect(page).to have_content("Not checked yet")
          click_link("Validate document - #{document1.name}")
        end
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
        "Applicants will be able to see this advice about how to prepare plans (Opens in a new window or tab)",
        href: public_planning_guides_path
      )
      expect(page).to have_link("Back", href: planning_application_validation_tasks_path(planning_application))

      # Reason must be present
      click_button "Save request"
      within(".govuk-error-summary") do
        expect(page).to have_content("There is a problem")
        expect(page).to have_content("Reason can't be blank")
      end

      fill_in "List all issues with the document.", with: "This is very invalid"
      click_button "Save request"

      expect(page).to have_content("Replacement document validation request successfully created.")
      expect(document1.reload.replacement_document_validation_request).to eq(ReplacementDocumentValidationRequest.last)
      within(".govuk-error-summary") do
        expect(page).to have_content("Invalid documents: 1")
      end
      within("#document-validation-tasks") do
        within("#document_#{document2.id}") do
          expect(page).to have_content("Not checked yet")
        end
        within("#document_#{document1.id}") do
          expect(page).to have_content("Invalid")
          click_link("Validate document - #{document1.name}")
        end
      end

      # View show page
      expect(page).to have_content("View request for a replacement document")
      within("#replacement-document-details") do
        expect(page).to have_content("Replacement for: #{document1.name}")
        expect(page).to have_content("This is very invalid")
        expect(page).to have_content(document1.replacement_document_validation_request.created_at.to_formatted_s(:day_month_year))
      end
      expect(page).to have_link("Back", href: planning_application_validation_tasks_path(planning_application))

      # Edit the request
      click_link "Edit request"
      fill_in "List all issues with the document.", with: "Not valid at all"
      click_button "Update request"
      expect(page).to have_content("Replacement document reason successfully updated.")

      # Delete the request
      within("#document-validation-tasks") do
        within("#document_#{document1.id}") do
          expect(page).to have_content("Invalid")
          click_link("Validate document - #{document1.name}")
        end
      end
      accept_confirm(text: "Are you sure?") do
        click_link("Delete request")
      end
      expect(page).to have_content("Validation request was successfully deleted.")
      expect(page).not_to have_content("Invalid documents")

      # The document returns to "Not checked yet"
      expect(document1.reload.replacement_document_validation_request).to eq(nil)
      expect(document1.invalidated_document_reason).to eq(nil)
      expect(document1.validated).to eq(nil)
      within("#document-validation-tasks") do
        within("#document_#{document1.id}") do
          expect(page).to have_content("Not checked yet")
          click_link("Validate document - #{document1.name}")
        end
      end

      # Mark same document as invalid again
      within("#validate-document") { choose "No" }
      click_button "Save"

      fill_in "List all issues with the document.", with: "Invalid doc"
      click_button "Save request"
      expect(page).to have_content("Replacement document validation request successfully created.")
      expect(document1.reload.replacement_document_validation_request).to eq(ReplacementDocumentValidationRequest.last)
      within("#document-validation-tasks") do
        within("#document_#{document1.id}") do
          expect(page).to have_content("Invalid")
        end
      end

      click_link "Send validation decision"
      expect(page).to have_content("You have marked items as invalid, so you cannot validate this application.")
    end

    it "I can mark documents as valid" do
      click_link "Check and validate"

      within("#document-validation-tasks") do
        within("#document_#{document1.id}") do
          click_link("Validate document - #{document1.name}")
        end
      end

      # Mark document as valid
      within("#validate-document") { choose "Yes" }
      click_button "Save"

      within("#document-validation-tasks") do
        within("#document_#{document1.id}") do
          expect(page).to have_content("Valid")
        end
        within("#document_#{document2.id}") do
          expect(page).to have_content("Not checked yet")
        end
      end

      click_link "Send validation decision"
      expect(page).to have_content("The application has not yet been marked as valid or invalid")
      expect(page).to have_link("Mark the application as valid")
    end
  end

  context "when an application has been invalidated" do
    let!(:planning_application) do
      create(:planning_application, :invalidated, local_authority: default_local_authority)
    end
    let!(:document1) { create(:document, :with_file, planning_application: planning_application) }
    let!(:document2) { create(:document, :with_file, planning_application: planning_application) }

    it "I can mark documents as invalid and cancel the validation request" do
      delivered_emails = ActionMailer::Base.deliveries.count

      click_link "Check and validate"

      within("#document-validation-tasks") do
        within("#document_#{document2.id}") do
          expect(page).to have_content("Not checked yet")
        end
        within("#document_#{document1.id}") do
          expect(page).to have_content("Not checked yet")
          click_link("Validate document - #{document1.name}")
        end
      end

      within("#validate-document") { choose "No" }
      click_button "Save"

      expect(page).to have_content("Request a replacement document")
      expect(page).to have_content("This request will be sent to the applicant immediately.")
      expect(page).to have_link(
        "Applicants will be able to see this advice about how to prepare plans (Opens in a new window or tab)",
        href: public_planning_guides_path
      )

      fill_in "List all issues with the document.", with: "Not readable"
      click_button "Send request"
      expect(page).to have_content("Replacement document validation request successfully created.")
      within(".govuk-error-summary") do
        expect(page).to have_content("Invalid documents: 1")
      end
      within("#document-validation-tasks") do
        within("#document_#{document1.id}") do
          expect(page).to have_content("Invalid")
        end
        within("#document_#{document2.id}") do
          expect(page).to have_content("Not checked yet")
        end
      end

      click_link "Send validation decision"
      expect(page).to have_content("This application has 1 unresolved validation request and 0 resolved validation requests")

      click_link "Application"
      click_button "Audit log"
      click_link "View all audits"

      within("#audit_#{Audit.last.id}") do
        expect(page).to have_content("Sent: validation request (replacement document#1)")
        expect(page).to have_content(assessor.name)
        expect(page).to have_content(document1.name.to_s)
        expect(page).to have_content("Invalid reason: Not readable")
        expect(page).to have_content(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
      end
      expect(ActionMailer::Base.deliveries.count).to eql(delivered_emails + 1)

      # Cancel request
      visit planning_application_validation_tasks_path(planning_application)
      within("#document-validation-tasks") do
        within("#document_#{document1.id}") do
          click_link("Validate document - #{document1.name}")
        end
      end

      within("#replacement-document-details") do
        expect(page).to have_content("Replacement for: #{document1.name}")
        expect(page).to have_content("Not readable")
        expect(page).to have_content(document1.replacement_document_validation_request.created_at.to_formatted_s(:day_month_year))
      end
      expect(page).not_to have_link("Edit request")
      expect(page).not_to have_link("Delete request")

      click_link "Cancel request"
      fill_in "Explain to the applicant why this request is being cancelled", with: "mistake"
      click_button "Confirm cancellation"
      expect(page).to have_content("Validation request was successfuly cancelled.")
      expect(document1.reload.replacement_document_validation_request).to eq(nil)
      expect(document1.invalidated_document_reason).to eq(nil)
      expect(document1.validated).to eq(nil)

      click_link "Application"
      click_button "Audit log"
      click_link "View all audits"

      within("#audit_#{Audit.last.id}") do
        expect(page).to have_content("Cancelled: validation request (replace document#1)")
        expect(page).to have_content(assessor.name)
        expect(page).to have_content("Reason: mistake")
        expect(page).to have_content(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
      end
      expect(ActionMailer::Base.deliveries.count).to eql(delivered_emails + 2)

      visit planning_application_validation_tasks_path(planning_application)
      expect(page).not_to have_content("Invalid documents")
      within("#document-validation-tasks") do
        within("#document_#{document1.id}") do
          expect(page).to have_content("Not checked yet")
        end
      end

      click_link "Send validation decision"
      expect(page).to have_content("This application has 0 unresolved validation requests and 0 resolved validation requests")
    end

    context "when an applicant has responded" do
      let!(:document_response) do
        create(:document, :with_other_file, planning_application: planning_application)
      end
      let!(:replacement_document_validation_request) do
        create(:replacement_document_validation_request, :with_response,
               planning_application: planning_application, old_document: document1, new_document: document_response)
      end

      before do
        # When new document is sent by the applicant the original document is archived
        replacement_document_validation_request.old_document.archive("replaced by new document")
      end

      it "can only view response and original document is archived" do
        # Can only view request
        visit planning_application_replacement_document_validation_request_path(
          planning_application, replacement_document_validation_request
        )
        expect(page).not_to have_link("Cancel request")
        expect(page).not_to have_link("Delete request")
        expect(page).not_to have_link("Edit request")

        visit planning_application_validation_tasks_path(planning_application)
        expect(page).to have_content("This application has 0 unresolved validation requests and 1 resolved validation request")

        within("#document-validation-tasks") do
          expect(page).not_to have_css("#document_#{document1.id}")
          within("#document_#{document2.id}") do
            expect(page).to have_content("Not checked yet")
          end
          within("#document_#{document_response.id}") do
            expect(page).to have_content("Not checked yet")
            click_link("Validate document - #{document_response.name.to_s.truncate(25)}")
          end
        end

        within("#validate-document") { choose "No" }
        click_button "Save"

        fill_in "List all issues with the document.", with: "Not valid"
        click_button "Send request"
        expect(page).to have_content("Replacement document validation request successfully created.")

        within("#document-validation-tasks") do
          within("#document_#{document_response.id}") do
            expect(page).to have_content("Invalid")
          end
        end

        request = ReplacementDocumentValidationRequest.last
        expect(document_response.replacement_document_validation_request).to eq(request)
        expect(request.old_document).to eq(document_response)
        expect(request.new_document).to eq(nil)

        click_link "Review validation requests"

        within("#replacement_document_validation_request_#{request.id}") do
          expect(page).to have_content("Replacement document")
          expect(page).to have_content("proposed-first-floor-plan.pdf")
          expect(page).to have_content("sent")
          expect(page).to have_link(
            "View and update",
            href: planning_application_replacement_document_validation_request_path(planning_application, request)
          )
        end
        within("#replacement_document_validation_request_#{replacement_document_validation_request.id}") do
          expect(page).to have_content("Replacement document")
          expect(page).to have_content("proposed-floorplan.png")
          expect(page).to have_content("Responded")
        end

        click_link "Back"
        click_link "Send validation decision"

        expect(page).to have_content("This application has 1 unresolved validation request and 1 resolved validation request")
      end
    end
  end

  context "when an application has been validated" do
    let!(:planning_application) do
      create(:planning_application, :in_assessment, local_authority: default_local_authority)
    end
    let!(:document1) { create(:document, :with_file, planning_application: planning_application) }

    it "does not allow you to validate documents" do
      click_link "Check and validate"

      within("#document-validation-tasks") do
        expect(page).to have_content("Planning application has already been validated")
      end
    end
  end

  context "when document is archived" do
    let!(:planning_application) do
      create(:planning_application, :invalidated, local_authority: default_local_authority)
    end

    let!(:document1) { create(:document, planning_application: planning_application, archived_at: 2.days.ago) }
    let!(:document2) { create(:document, planning_application: planning_application) }

    it "does not appear in the validate document list" do
      click_link "Check and validate"

      within("#document-validation-tasks") do
        within("#document_#{document2.id}") do
          expect(page).to have_content("Not checked yet")
          expect(page).to have_link("Validate document - #{document2.name}")
        end
        expect(page).to have_no_css("#document_#{document1.id}")
      end
    end
  end

  context "when there are invalid documents" do
    let!(:planning_application) do
      create(:planning_application, :invalidated, local_authority: default_local_authority)
    end
    let!(:document) { create(:document, planning_application: planning_application, validated: false) }

    context "when there is an open or pending replacement document validation request" do
      let!(:replacement_document_validation_request) do
        create(:replacement_document_validation_request, :open, planning_application: planning_application, old_document: document)
      end

      it "does show a invalid documents warning" do
        click_link "Check and validate"
        expect(page).to have_content("Invalid documents: 1")

        click_link "Check documents"
        expect(page).to have_content("Invalid documents: 1")
      end
    end

    context "when there is a cancelled replacement document validation request" do
      let!(:replacement_document_validation_request) do
        create(:replacement_document_validation_request, :cancelled, planning_application: planning_application, old_document: document)
      end

      it "does not show a warning" do
        click_link "Check and validate"
        expect(page).not_to have_content("Invalid documents")
      end
    end

    context "when there is no replacement document validation request" do
      it "does not show a warning" do
        click_link "Check and validate"
        expect(page).not_to have_content("Invalid documents")
      end
    end

    context "when document is archived" do
      let!(:document) { create(:document, planning_application: planning_application, validated: false, archived_at: Time.zone.now) }
      let!(:replacement_document_validation_request) do
        create(:replacement_document_validation_request, planning_application: planning_application, old_document: document)
      end

      it "does not show a warning" do
        expect(page).not_to have_content("Invalid documents")
      end
    end
  end

  context "Invalidation updates replacement document validation request" do
    let!(:planning_application) do
      create(:planning_application, :not_started, local_authority: default_local_authority)
    end
    let!(:replacement_document_validation_request) do
      create(:replacement_document_validation_request, planning_application: planning_application,
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
      expect(replacement_document_validation_request.notified_at).to be_a Date
    end
  end
end
