# frozen_string_literal: true

require "bops_applicants_helper"

RSpec.describe "Description change validation requests" do
  let!(:local_authority) { create(:local_authority, :default) }
  let!(:user) { create(:user, :assessor, local_authority:) }

  let(:planning_application) do
    create(
      :planning_application,
      :planning_permission,
      :invalidated,
      local_authority: local_authority,
      description: "Application for the erection of 47 dwellings",
      address_1: "60-62 Commercial Street",
      town: "London",
      postcode: "E1 6LT"
    )
  end

  let(:reference) { planning_application.reference }
  let(:change_access_id) { planning_application.change_access_id }

  let(:access_control_params) do
    {planning_application_reference: reference, change_access_id: change_access_id}.to_query
  end

  around do |example|
    travel_to("2025-05-23T12:00:00Z") { example.run }
  end

  context "when a validation request doesn't exist" do
    it "returns an error page" do
      expect {
        visit "/replacement_document_validation_requests/123"
      }.to raise_error(BopsCore::Errors::NotFoundError)
    end
  end

  context "when a validation request exists" do
    let!(:validation_request) do
      create(
        :replacement_document_validation_request,
        validation_request_status,
        planning_application:,
        reason: "The document is incorrectly labelled"
      )
    end

    context "and the request is open" do
      let(:validation_request_status) { :open }

      context "and the access control parameters are missing" do
        let(:access_control_params) { "" }

        it "returns an error page for the show action" do
          expect {
            visit "/replacement_document_validation_requests/#{validation_request.id}?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end

        it "returns an error page for the edit action" do
          expect {
            visit "/replacement_document_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end
      end

      context "and the access control parameters present" do
        it "returns an error page for the show action" do
          expect {
            visit "/replacement_document_validation_requests/#{validation_request.id}?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end

        it "can be responded to" do
          visit "/replacement_document_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
          expect(page).to have_selector("h1", text: "Provide a replacement document")
          expect(page).to have_content("You must submit your response by 16 June 2025")
          expect(page).to have_link("Read guidance on how to prepare plans correctly", href: "http://planx.bops.services/planning_guides")

          within "#replacement-document-requested" do
            expect(page).to have_selector("h3", text: "Name of document previously submitted:")
            expect(page).to have_content("proposed-floorplan.png")
          end

          within "#replacement-document-comment" do
            expect(page).to have_selector("h3", text: "Reason why you need to replace this document:")
            expect(page).to have_content("The document is incorrectly labelled")
          end

          click_button "Submit"
          expect(page).to have_selector("[role=alert] p", text: "There was a problem sending your response to the case officer")
          expect(page).to have_link("contact us", href: "mailto:feedback_email@planx.uk")
          expect(page).to have_content("Select a file to upload")

          attach_file "Upload a replacement document", "spec/fixtures/images/proposed-roofplan.png"

          click_button "Submit"
          expect(page).to have_selector("h1", text: "Your planning application")
          expect(page).to have_selector("[role=alert] p", text: "Your response has been sent to the case officer")

          within "#replacement-document-validation-requests" do
            expect(page).to have_selector("h3", text: "Provide replacement documents")
            expect(page).to have_selector("strong.govuk-tag--green", text: "Complete")
            expect(page).to have_link("Upload proposed-floorplan.png", href: %r{\A/replacement_document_validation_requests/#{validation_request.id}})

            click_link "Upload proposed-floorplan.png"
          end

          expect(page).to have_selector("h1", text: "Provide a replacement document")

          within "#replacement-document-requested" do
            expect(page).to have_selector("h2", text: "Name of file on submission:")
            expect(page).to have_content("proposed-floorplan.png")
          end

          within "#replacement-document-comment" do
            expect(page).to have_selector("h2", text: "Case officer's reason for requesting the document:")
            expect(page).to have_content("The document is incorrectly labelled")
          end

          within "#old-document" do
            expect(page).to have_selector("h3", text: "Old document")
            expect(page).to have_selector("img[src^='http://planx.bops-applicants.services/files/']")
            expect(page).to have_link("proposed-floorplan.png", href: %r{\Ahttp://planx\.bops-applicants\.services/files/})
          end

          within "#replacement-document" do
            expect(page).to have_selector("h3", text: "Replacement document")
            expect(page).to have_selector("img[src^='http://planx.bops-applicants.services/files/']")
            expect(page).to have_link("proposed-roofplan.png", href: %r{\Ahttp://planx\.bops-applicants\.services/files/})
          end
        end
      end
    end

    context "and the request is cancelled" do
      let(:validation_request_status) { :cancelled }

      context "and the access control parameters are missing" do
        let(:access_control_params) { "" }

        it "returns an error page for the show action" do
          expect {
            visit "/replacement_document_validation_requests/#{validation_request.id}?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end

        it "returns an error page for the edit action" do
          expect {
            visit "/replacement_document_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end
      end

      context "and the access control parameters present" do
        it "shows the reason for the cancellation" do
          visit "/replacement_document_validation_requests/#{validation_request.id}?#{access_control_params}"
          expect(page).to have_selector("h1", text: "Cancelled request to provide a replacement document")

          within "#cancellation-reason" do
            expect(page).to have_content("Made by mistake!")
            expect(page).to have_content("23 May 2025 13:00")
          end
        end

        it "returns an error page for the edit action" do
          expect {
            visit "/replacement_document_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end
      end
    end

    context "and the request is closed" do
      let(:validation_request_status) { :closed }

      context "and the access control parameters are missing" do
        let(:access_control_params) { "" }

        it "returns an error page for the show action" do
          expect {
            visit "/replacement_document_validation_requests/#{validation_request.id}?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end

        it "returns an error page for the edit action" do
          expect {
            visit "/replacement_document_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end
      end

      context "and the access control parameters present" do
        let!(:old_document) { validation_request.old_document }
        let!(:new_document) { create(:document, :with_other_file, planning_application:) }
        let!(:old_preview) { old_document.representation(resize_to_fill: [240, 180, gravity: "North"]) }
        let!(:new_preview) { new_document.representation(resize_to_fill: [240, 180, gravity: "North"]) }

        before do
          validation_request.new_document = new_document
        end

        it "shows the replacement document uploaded" do
          visit "/replacement_document_validation_requests/#{validation_request.id}?#{access_control_params}"
          expect(page).to have_selector("h1", text: "Provide a replacement document")

          within "#replacement-document-requested" do
            expect(page).to have_selector("h2", text: "Name of file on submission:")
            expect(page).to have_content("proposed-floorplan.png")
          end

          within "#replacement-document-comment" do
            expect(page).to have_selector("h2", text: "Case officer's reason for requesting the document:")
            expect(page).to have_content("The document is incorrectly labelled")
          end

          within "#old-document" do
            expect(page).to have_selector("h3", text: "Old document")
            expect(page).to have_selector("img[src^='http://planx.bops-applicants.services/files/#{old_preview.key}']")
            expect(page).to have_link("proposed-floorplan.png", href: %r{\Ahttp://planx\.bops-applicants\.services/files/#{old_document.blob_key}})
          end

          within "#replacement-document" do
            expect(page).to have_selector("h3", text: "Replacement document")
            expect(page).to have_selector("img[src^='http://planx.bops-applicants.services/files/#{new_preview.key}']")
            expect(page).to have_link("proposed-first-floor-plan.pdf", href: %r{\Ahttp://planx\.bops-applicants\.services/files/#{new_document.blob_key}})
          end
        end

        it "returns an error page for the edit action" do
          expect {
            visit "/replacement_document_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end
      end
    end
  end
end
