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
        visit "/additional_document_validation_requests/123"
      }.to raise_error(BopsCore::Errors::NotFoundError)
    end
  end

  context "when a validation request exists" do
    let!(:validation_request) do
      create(
        :additional_document_validation_request,
        validation_request_status,
        planning_application:,
        reason: "Because the site is in a conservation area",
        specific_attributes: {
          document_request_type: "Arboricultural Report"
        }
      )
    end

    context "and the request is open" do
      let(:validation_request_status) { :open }

      context "and the access control parameters are missing" do
        let(:access_control_params) { "" }

        it "returns an error page for the show action" do
          expect {
            visit "/additional_document_validation_requests/#{validation_request.id}?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end

        it "returns an error page for the edit action" do
          expect {
            visit "/additional_document_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end
      end

      context "and the access control parameters present" do
        it "returns an error page for the show action" do
          expect {
            visit "/additional_document_validation_requests/#{validation_request.id}?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end

        it "can be responded to" do
          visit "/additional_document_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
          expect(page).to have_selector("h1", text: "Provide a new document")
          expect(page).to have_content("You must submit your response by 16 June 2025")
          expect(page).to have_link("Read guidance on how to prepare plans correctly", href: "http://planx.bops.services/planning_guides")

          within "#additional-document-requested" do
            expect(page).to have_content("Arboricultural Report")
          end

          within "#additional-document-comment" do
            expect(page).to have_content("Because the site is in a conservation area")
          end

          click_button "Submit"
          expect(page).to have_selector("[role=alert] p", text: "There was a problem sending your response to the case officer")
          expect(page).to have_link("contact us", href: "mailto:feedback_email@planx.uk")
          expect(page).to have_content("Select some files to upload")

          attach_file "Upload additional document(s)", "spec/fixtures/images/proposed-roofplan.png"

          click_button "Submit"
          expect(page).to have_selector("h1", text: "Your planning application")
          expect(page).to have_selector("[role=alert] p", text: "Your response has been sent to the case officer")

          within "#additional-document-validation-requests" do
            expect(page).to have_selector("h3", text: "Provide new or missing documents")
            expect(page).to have_selector("strong.govuk-tag--green", text: "Complete")
            expect(page).to have_link("Upload new document", href: %r{\A/additional_document_validation_requests/#{validation_request.id}})

            click_link "Upload new document"
          end

          expect(page).to have_selector("h1", text: "Confirm document uploaded")

          within "#additional-document-requested" do
            expect(page).to have_selector("h2", text: "Document requested:")
            expect(page).to have_content("Arboricultural Report")
          end

          within "#additional-document-comment" do
            expect(page).to have_selector("h2", text: "Comment from case officer:")
            expect(page).to have_content("Because the site is in a conservation area")
          end

          within "#additional-document-response" do
            expect(page).to have_selector("h2", text: "Document you uploaded in response:")

            within "li:nth-of-type(1)" do
              expect(page).to have_selector("img[src^='http://planx.bops-applicants.services/files/']")
              expect(page).to have_link("proposed-roofplan.png", href: %r{\Ahttp://planx\.bops-applicants\.services/files/})
            end
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
            visit "/additional_document_validation_requests/#{validation_request.id}?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end

        it "returns an error page for the edit action" do
          expect {
            visit "/additional_document_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end
      end

      context "and the access control parameters present" do
        it "shows the reason for the cancellation" do
          visit "/additional_document_validation_requests/#{validation_request.id}?#{access_control_params}"
          expect(page).to have_selector("h1", text: "Cancelled request to provide a new document")

          within "#cancellation-reason" do
            expect(page).to have_content("Made by mistake!")
            expect(page).to have_content("23 May 2025 13:00")
          end
        end

        it "returns an error page for the edit action" do
          expect {
            visit "/additional_document_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
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
            visit "/additional_document_validation_requests/#{validation_request.id}?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end

        it "returns an error page for the edit action" do
          expect {
            visit "/additional_document_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end
      end

      context "and the access control parameters present" do
        let!(:document_1) { create(:document, :with_file, planning_application:) }
        let!(:document_2) { create(:document, :with_other_file, planning_application:) }
        let!(:preview_1) { document_1.representation(resize_to_fill: [360, 240, gravity: "North"]) }
        let!(:preview_2) { document_2.representation(resize_to_fill: [360, 240, gravity: "North"]) }

        before do
          validation_request.additional_documents << document_1
          validation_request.additional_documents << document_2
        end

        it "shows the additional documents uploaded", skip: "flaky" do
          visit "/additional_document_validation_requests/#{validation_request.id}?#{access_control_params}"
          expect(page).to have_selector("h1", text: "Confirm documents uploaded")

          within "#additional-document-requested" do
            expect(page).to have_selector("h2", text: "Documents requested:")
            expect(page).to have_content("Arboricultural Report")
          end

          within "#additional-document-comment" do
            expect(page).to have_selector("h2", text: "Comment from case officer:")
            expect(page).to have_content("Because the site is in a conservation area")
          end

          within "#additional-document-response" do
            expect(page).to have_selector("h2", text: "Documents you uploaded in response:")

            within "li:nth-of-type(1)" do
              expect(page).to have_selector("img[src^='http://planx.bops-applicants.services/files/#{preview_1.key}']")
              expect(page).to have_link("proposed-floorplan.png", href: %r{\Ahttp://planx\.bops-applicants\.services/files/#{document_1.blob_key}})
            end

            within "li:nth-of-type(2)" do
              expect(page).to have_selector("img[src^='http://planx.bops-applicants.services/files/#{preview_2.key}']")
              expect(page).to have_link("proposed-first-floor-plan.pdf", href: %r{\Ahttp://planx\.bops-applicants\.services/files/#{document_2.blob_key}})
            end
          end
        end

        it "returns an error page for the edit action" do
          expect {
            visit "/additional_document_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end
      end
    end
  end
end
