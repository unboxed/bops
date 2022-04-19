# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Requesting a new document for a planning application", type: :system do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create :user, :assessor, local_authority: default_local_authority }

  let!(:planning_application) do
    create :planning_application, :invalidated, local_authority: default_local_authority
  end

  let!(:api_user) { create :api_user, name: "Api Wizard" }

  before do
    travel_to Time.zone.local(2021, 1, 1)
    sign_in assessor
    visit planning_application_path(planning_application)
  end

  it "allows for a document creation request to be created and sent to the applicant" do
    delivered_emails = ActionMailer::Base.deliveries.count
    click_link "Validate application"
    click_link "Start now"
    click_link "Validate required documents are on application"
    click_link "Add a request for a missing document"

    expect(page).to have_content("Request a new document")
    expect(page).to have_content("This request will be sent to the applicant immediately.")

    expect(page).to have_link(
      "Applicants will be able to see this advice about how to prepare plans (Opens in a new window or tab)",
      href: public_planning_guides_path
    )

    fill_in "Please specify the new document type:", with: "Backyard plans"
    fill_in "Please specify the reason you have requested this document?", with: "Application is missing a rear view."

    click_button "Add"
    expect(page).to have_content("Additional document request successfully created.")

    click_link "Application"
    click_button "Audit log"
    click_link "View all audits"

    expect(page).to have_text("Sent: validation request (new document#1)")
    expect(page).to have_text("Document: Backyard plans")
    expect(page).to have_text("Reason: Application is missing a rear view.")
    expect(page).to have_text(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
    expect(ActionMailer::Base.deliveries.count).to eql(delivered_emails + 1)
  end

  it "displays the details of the received request in the audit log" do
    create :audit, planning_application_id: planning_application.id,
                   activity_type: "additional_document_validation_request_received", activity_information: 1, audit_comment: "roof_plan.pdf", api_user: api_user

    sign_in assessor
    visit planning_application_path(planning_application)

    click_button "Audit log"
    click_link "View all audits"

    expect(page).to have_text("Received: request for change (new document#1)")
    expect(page).to have_text("roof_plan.pdf")
    expect(page).to have_text("Applicant / Agent via Api Wizard")
  end

  context "Invalidation updates additional document validation request" do
    it "updates the notified_at date of an open request when application is invalidated" do
      new_planning_application = create :planning_application, :not_started, local_authority: default_local_authority

      request = create(
        :additional_document_validation_request,
        planning_application: new_planning_application,
        state: "pending",
        created_at: 12.days.ago
      )

      visit planning_application_path(new_planning_application)
      click_link "Validate application"
      click_link "Start now"
      click_link "Send validation decision"
      expect(request.notified_at).to be_nil

      click_button "Mark the application as invalid"

      expect(page).to have_content("Application has been invalidated")

      new_planning_application.reload
      expect(new_planning_application.status).to eq("invalidated")

      request.reload

      expect(request.notified_at).not_to be_nil
    end
  end

  context "when application is not started" do
    let!(:planning_application) do
      create(:planning_application, :not_started, local_authority: default_local_authority)
    end

    before do
      create(:document, :with_file, planning_application: planning_application)
      create(:document, :with_other_file, planning_application: planning_application)
    end

    it "I can see the list of active documents when I go to validate" do
      visit planning_application_validation_tasks_path(planning_application)

      within("#additional-documents-validation-task") do
        expect(page).to have_content("Check for missing documents")
        expect(page).to have_content("Not checked yet")
      end

      click_link "Validate required documents are on application"

      expect(page).to have_content("Check the documents provided")
      expect(page).to have_content("Check all necessary documents have been provided and add requests for any missing documents.")
      expect(page).to have_link(
        "Add a request for a missing document",
        href: new_planning_application_additional_document_validation_request_path(planning_application)
      )

      within(".govuk-table.current-documents") do
        within(".govuk-table__body") do
          rows = page.all(".govuk-table__row")

          within(rows[0]) do
            cells = page.all(".govuk-table__cell")

            within(cells[0]) do
              expect(page).to have_link("View in new window")
            end

            within(cells[1]) do
              expect(page).to have_content("File name: proposed-floorplan.png")
              expect(page).to have_content("Date received: 1 January 2021")
              expect(page).to have_content("Included in decision notice: No")
              expect(page).to have_content("Public: No")
            end
          end

          within(rows[1]) do
            cells = page.all(".govuk-table__cell")

            within(cells[0]) do
              expect(page).to have_link("View in new window")
            end

            within(cells[1]) do
              expect(page).to have_content("File name: proposed-first-floor-plan.pdf")
              expect(page).to have_content("Date received: 1 January 2021")
              expect(page).to have_content("Included in decision notice: No")
              expect(page).to have_content("Public: No")
            end
          end
        end
      end

      within(".govuk-button-group") do
        expect(page).to have_button("Save")
        expect(page).to have_link(
          "Back", href: planning_application_validation_tasks_path(planning_application)
        )
      end
    end

    it "I can validate that there are no missing documents" do
      visit planning_application_validation_tasks_path(planning_application)
      click_link "Validate required documents are on application"
      click_button "Save"

      expect(page).to have_content("Documents required are marked as valid")

      within("#additional-documents-validation-task") do
        expect(page).to have_content("Valid")
      end

      expect(planning_application.reload.documents_missing).to eq(false)
      expect(AdditionalDocumentValidationRequest.all.length).to eq(0)
    end

    it "I get validation errors when I omit required information" do
      visit planning_application_validation_tasks_path(planning_application)
      click_link "Validate required documents are on application"
      click_link "Add a request for a missing document"
      click_button "Add"

      within(".govuk-error-message#additional-document-validation-request-document-request-type-error") do
        expect(page).to have_content("Please fill in the document request type.")
      end

      within(".govuk-error-message#additional-document-validation-request-document-request-reason-error") do
        expect(page).to have_content("Please fill in the reason for this document request.")
      end
    end

    it "I can request missing documents meaning the required documents are invalid" do
      visit planning_application_validation_tasks_path(planning_application)
      click_link "Validate required documents are on application"
      click_link "Add a request for a missing document"
      click_button "Add"

      expect(page).to have_content("Request a new document")

      expect(page).to have_link(
        "Applicants will be able to see this advice about how to prepare plans (Opens in a new window or tab)",
        href: public_planning_guides_path
      )
      expect(page).to have_content(
        "This request will be added to the application. The requests will not be sent until the application is marked as invalid."
      )

      fill_in "Please specify the new document type:", with: "Backyard plans"
      fill_in "Please specify the reason you have requested this document?", with: "Application is missing a rear view."

      click_button "Add"

      expect(page).to have_content("Additional document request successfully created.")

      within("#additional-documents-validation-task") do
        expect(page).to have_content("Invalid")
      end

      expect(planning_application.reload.documents_missing).to be_truthy
      expect(AdditionalDocumentValidationRequest.all.length).to eq(1)

      click_link "Validate required documents are on application"

      additional_document_validation_request = AdditionalDocumentValidationRequest.last

      within(".govuk-table#additional-document-validation-requests-table") do
        expect(page).to have_content("New document requested")
        expect(page).to have_content("Document requested: #{additional_document_validation_request.document_request_type}")
        expect(page).to have_content("Reason: #{additional_document_validation_request.document_request_reason}")
        expect(page).to have_content("Requested at: #{additional_document_validation_request.created_at}")
      end

      within(".govuk-button-group") do
        click_button "Save"
      end

      expect(page).to have_content("Documents required are marked as invalid")

      within("#additional-documents-validation-task") do
        expect(page).to have_content("Invalid")
      end
    end

    context "when required documents are marked as invalid" do
      before do
        planning_application.update(documents_missing: true)
      end

      let!(:additional_document_validation_request) do
        create(
          :additional_document_validation_request, :pending, planning_application: planning_application
        )
      end

      it "I can edit the additional document validation request" do
        visit planning_application_validation_tasks_path(planning_application)
        within("#additional-documents-validation-task") do
          expect(page).to have_content("Invalid")
        end

        click_link "Validate required documents are on application"
        click_link "Edit request"

        expect(page).to have_current_path(
          edit_planning_application_additional_document_validation_request_path(planning_application, additional_document_validation_request)
        )

        fill_in "Please specify the new document type:", with: "Floor plans"
        fill_in "Please specify the reason you have requested this document?", with: "Application is missing a floor plan."

        within(".govuk-button-group") do
          expect(page).to have_link(
            "Back", href: planning_application_validation_tasks_path(planning_application)
          )
          click_button "Update"
        end

        expect(page).to have_content("Additional document request successfully updated")

        within("#additional-documents-validation-task") do
          expect(page).to have_content("Invalid")
        end

        click_link "Validate required documents are on application"

        within(".govuk-table#additional-document-validation-requests-table") do
          expect(page).to have_content("New document requested")
          expect(page).to have_content("Document requested: Floor plans")
          expect(page).to have_content("Reason: Application is missing a floor plan.")
          expect(page).to have_content("Requested at: #{additional_document_validation_request.created_at}")
        end
      end

      it "I can delete the additional document validation request" do
        visit planning_application_validation_tasks_path(planning_application)
        click_link "Validate required documents are on application"
        accept_confirm(text: "Are you sure?") do
          click_link("Delete request")
        end

        expect(page).to have_content("Validation request was successfully deleted.")

        within("#additional-documents-validation-task") do
          expect(page).to have_content("Not checked yet")
        end

        expect(planning_application.reload.documents_missing).to be_nil
        expect(AdditionalDocumentValidationRequest.all.length).to eq(0)
      end
    end
  end

  context "when application is invalidated" do
    let!(:planning_application) do
      create :planning_application, :invalidated, local_authority: default_local_authority, documents_missing: true
    end

    let!(:additional_document_validation_request) do
      create(
        :additional_document_validation_request, :open,
        planning_application: planning_application
      )
    end

    it "I can view the request" do
      visit planning_application_validation_tasks_path(planning_application)
      click_link "Validate required documents are on application"

      expect(page).to have_content("Check the documents provided")

      within(".govuk-table#additional-document-validation-requests-table") do
        expect(page).to have_content("New document requested")
        expect(page).to have_content("Document requested: #{additional_document_validation_request.document_request_type}")
        expect(page).to have_content("Reason: #{additional_document_validation_request.document_request_reason}")
        expect(page).to have_content("Requested at: #{additional_document_validation_request.created_at}")
      end

      expect(page).to have_link(
        "Cancel request",
        href: cancel_confirmation_planning_application_additional_document_validation_request_path(planning_application, additional_document_validation_request)
      )
      expect(page).not_to have_link("Edit request")
      expect(page).not_to have_link("Delete request")

      within(".govuk-button-group") do
        expect(page).to have_link(
          "Back", href: planning_application_validation_tasks_path(planning_application)
        )
        expect(page).to have_button("Save")
      end
    end

    it "I can cancel the request" do
      visit planning_application_validation_tasks_path(planning_application)
      click_link "Validate required documents are on application"
      click_link "Cancel request"

      fill_in "Explain to the applicant why this request is being cancelled", with: "Mistake"
      click_button "Confirm cancellation"

      expect(page).to have_content("Validation request was successfuly cancelled.")

      within(".govuk-table.cancelled-requests") do
        within("#additional_document_validation_request_#{additional_document_validation_request.id}") do
          expect(page).to have_content("New document")
          expect(page).to have_content("Mistake")
          expect(page).to have_content(additional_document_validation_request.reload.cancelled_at)
        end
      end

      expect(planning_application.reload.documents_missing).to be_nil
      expect(AdditionalDocumentValidationRequest.last.state).to eq("cancelled")

      click_link "Validation tasks"

      within("#additional-documents-validation-task") do
        expect(page).to have_content("Not checked yet")
      end

      click_link "Application"
      click_button "Audit log"
      click_link "View all audits"

      within("#audit_#{Audit.last.id}") do
        expect(page).to have_content("Cancelled: validation request (new document#1)")
        expect(page).to have_content(assessor.name)
        expect(page).to have_content("Reason: Mistake")
        expect(page).to have_content(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
      end
    end

    it "I cannot edit the request" do
      visit edit_planning_application_additional_document_validation_request_path(
        planning_application, additional_document_validation_request
      )

      expect(page).to have_content("forbidden")
      expect(page).not_to have_link("Edit request")
    end

    context "when overdue" do
      before { travel_to Time.zone.local(2022, 1, 1) }

      it "I can see an overdue request" do
        visit planning_application_validation_requests_path(planning_application)

        expect(page).to have_content("overdue")
      end
    end

    context "when applicant has responded" do
      let!(:additional_document_validation_request) do
        create(
          :additional_document_validation_request, :open,
          planning_application: planning_application
        )
      end

      let!(:document) { create(:document, :with_file, planning_application: planning_application) }

      before do
        additional_document_validation_request.update(state: "closed")
        additional_document_validation_request.documents << document
      end

      it "I can see the new document in the validate documents list" do
        visit planning_application_validation_tasks_path(planning_application)

        within("#additional-documents-validation-task") do
          expect(page).to have_content("Not checked yet")
        end

        click_link "Validate required documents are on application"

        within(".govuk-table.current-documents") do
          within(".govuk-table__body") do
            within(".govuk-table__row") do
              cells = page.all(".govuk-table__cell")

              within(cells[0]) do
                expect(page).to have_link("View in new window")
              end

              within(cells[1]) do
                expect(page).to have_content("File name: proposed-floorplan.png")
                expect(page).to have_content("Date received: 1 January 2021")
                expect(page).to have_content("Included in decision notice: No")
                expect(page).to have_content("Public: No")
              end
            end
          end
        end
      end
    end
  end

  context "when an application has been validated" do
    let!(:planning_application) do
      create(:planning_application, :in_assessment, local_authority: default_local_authority)
    end

    it "does not allow you to validate for missing documents" do
      visit planning_application_validation_tasks_path(planning_application)

      within("#additional-documents-validation-task") do
        expect(page).to have_content("Planning application has already been validated")
      end
    end
  end
end
