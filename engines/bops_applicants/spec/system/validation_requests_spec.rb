# frozen_string_literal: true

require "bops_applicants_helper"

RSpec.describe "Validation requests" do
  let!(:local_authority) { create(:local_authority, :default) }
  let!(:user) { create(:user, :assessor, local_authority:) }
  let(:planning_application_status) { :not_started }

  let(:planning_application) do
    create(
      :planning_application,
      :planning_permission,
      planning_application_status,
      local_authority: local_authority,
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

  it "displays information about the planning application" do
    visit "/validation_requests?#{access_control_params}"
    expect(page).to have_title("Your planning application - PlanX BOPS")

    expect(page).to have_selector("h1", text: "Your planning application")
    expect(page).to have_content("At: 60-62 Commercial Street, London, E1 6LT")
    expect(page).to have_content("Date received: 23 May 2025")
    expect(page).to have_content("Application number: #{reference}")
  end

  context "when the application has a request to change the description" do
    let!(:validation_request) do
      create(:description_change_validation_request, validation_request_status, planning_application:)
    end

    context "and the request is open" do
      let(:validation_request_status) { :open }

      it "shows the request in the list and its status" do
        visit "/validation_requests?#{access_control_params}"
        expect(page).to have_selector("h1", text: "Your planning application")

        within "#description-change-validation-requests" do
          expect(page).to have_selector("h3", text: "Confirm change to your application description")
          expect(page).to have_selector("strong.govuk-tag--grey", text: "Not started")
          expect(page).to have_link("Check description", href: %r{\A/description_change_validation_requests/#{validation_request.id}/edit})
        end
      end
    end

    context "and the request is cancelled" do
      let(:validation_request_status) { :cancelled }

      it "shows the request in the list and its status" do
        visit "/validation_requests?#{access_control_params}"
        expect(page).to have_selector("h1", text: "Your planning application")

        within "#description-change-validation-requests" do
          expect(page).to have_selector("h3", text: "Confirm change to your application description")
          expect(page).to have_selector("strong.govuk-tag--red", text: "Cancelled")
          expect(page).to have_link("Check description", href: %r{\A/description_change_validation_requests/#{validation_request.id}})
        end
      end
    end

    context "and the request is closed" do
      let(:validation_request_status) { :closed }

      it "shows the request in the list and its status" do
        visit "/validation_requests?#{access_control_params}"
        expect(page).to have_selector("h1", text: "Your planning application")

        within "#description-change-validation-requests" do
          expect(page).to have_selector("h3", text: "Confirm change to your application description")
          expect(page).to have_selector("strong.govuk-tag--green", text: "Complete")
          expect(page).to have_link("Check description", href: %r{\A/description_change_validation_requests/#{validation_request.id}})
        end
      end
    end
  end

  context "when the application has a request to extend the expiry date" do
    let!(:validation_request) do
      create(:time_extension_validation_request, validation_request_status, planning_application:)
    end

    context "and the request is open" do
      let(:validation_request_status) { :open }

      it "shows the request in the list and its status" do
        visit "/validation_requests?#{access_control_params}"
        expect(page).to have_selector("h1", text: "Your planning application")

        within "#time-extension-validation-requests" do
          expect(page).to have_selector("h3", text: "Confirm time extension request")
          expect(page).to have_selector("strong.govuk-tag--grey", text: "Not started")
          expect(page).to have_link("Confirm expiry date", href: %r{\A/time_extension_validation_requests/#{validation_request.id}/edit})
        end
      end
    end

    context "and the request is cancelled" do
      let(:validation_request_status) { :cancelled }

      it "shows the request in the list and its status" do
        visit "/validation_requests?#{access_control_params}"
        expect(page).to have_selector("h1", text: "Your planning application")

        within "#time-extension-validation-requests" do
          expect(page).to have_selector("h3", text: "Confirm time extension request")
          expect(page).to have_selector("strong.govuk-tag--red", text: "Cancelled")
          expect(page).to have_link("Confirm expiry date", href: %r{\A/time_extension_validation_requests/#{validation_request.id}})
        end
      end
    end

    context "and the request is closed" do
      let(:validation_request_status) { :closed }

      it "shows the request in the list and its status" do
        visit "/validation_requests?#{access_control_params}"
        expect(page).to have_selector("h1", text: "Your planning application")

        within "#time-extension-validation-requests" do
          expect(page).to have_selector("h3", text: "Confirm time extension request")
          expect(page).to have_selector("strong.govuk-tag--green", text: "Complete")
          expect(page).to have_link("Confirm expiry date", href: %r{\A/time_extension_validation_requests/#{validation_request.id}})
        end
      end
    end
  end

  context "when the application has not been started" do
    context "and it has a request to upload a new version of a document" do
      let!(:validation_request) do
        create(:replacement_document_validation_request, :open, planning_application:)
      end

      it "doesn't show the validation request" do
        visit "/validation_requests?#{access_control_params}"
        expect(page).to have_selector("h1", text: "Your planning application")
        expect(page).not_to have_selector("h3", text: "Provide replacement documents")
      end
    end

    context "and it has a request to upload additional documents" do
      let!(:validation_request) do
        create(:additional_document_validation_request, :open, planning_application:)
      end

      it "doesn't show the validation request" do
        visit "/validation_requests?#{access_control_params}"
        expect(page).to have_selector("h1", text: "Your planning application")
        expect(page).not_to have_selector("h3", text: "Provide new or missing documents")
      end
    end

    context "and it has a request to change the red line boundary" do
      let!(:validation_request) do
        create(:red_line_boundary_change_validation_request, :open, planning_application:)
      end

      it "doesn't show the validation request" do
        visit "/validation_requests?#{access_control_params}"
        expect(page).to have_selector("h1", text: "Your planning application")
        expect(page).not_to have_selector("h3", text: "Confirm changes to the red line boundary")
      end
    end

    context "and it has a request to change the application fee" do
      let!(:validation_request) do
        create(:fee_change_validation_request, :open, planning_application:)
      end

      it "doesn't show the validation request" do
        visit "/validation_requests?#{access_control_params}"
        expect(page).to have_selector("h1", text: "Your planning application")
        expect(page).not_to have_selector("h3", text: "Respond to fee change request")
      end
    end

    context "and it has a request to confirm ownership" do
      let!(:validation_request) do
        create(:ownership_certificate_validation_request, :open, planning_application:)
      end

      it "doesn't show the validation request" do
        visit "/validation_requests?#{access_control_params}"
        expect(page).to have_selector("h1", text: "Your planning application")
        expect(page).not_to have_selector("h3", text: "Confirm ownership of the land")
      end
    end

    context "and it has a request to change other things" do
      let!(:validation_request) do
        create(:other_change_validation_request, :open, planning_application:)
      end

      it "doesn't show the validation request" do
        visit "/validation_requests?#{access_control_params}"
        expect(page).to have_selector("h1", text: "Your planning application")
        expect(page).not_to have_selector("h3", text: "Respond to other requests")
      end
    end

    context "and it has a request to agree pre-commencement conditions" do
      let!(:validation_request) do
        create(:pre_commencement_condition_validation_request, :open, planning_application:)
      end

      it "doesn't show the validation request" do
        visit "/validation_requests?#{access_control_params}"
        expect(page).to have_selector("h1", text: "Your planning application")
        expect(page).not_to have_selector("h3", text: "Respond to pre-commencement conditions")
      end
    end

    context "and it has a request to agree heads of terms" do
      let!(:validation_request) do
        create(:heads_of_terms_validation_request, :open, planning_application:)
      end

      it "doesn't show the validation request" do
        visit "/validation_requests?#{access_control_params}"
        expect(page).to have_selector("h1", text: "Your planning application")
        expect(page).not_to have_selector("h3", text: "Respond to heads of terms")
      end
    end
  end

  context "when the application has been invalidated" do
    let(:planning_application_status) { :invalidated }

    context "and it has a request to upload a new version of a document" do
      let!(:validation_request) do
        create(:replacement_document_validation_request, validation_request_status, planning_application:)
      end

      context "and the request is open" do
        let(:validation_request_status) { :open }

        it "shows the request in the list and its status" do
          visit "/validation_requests?#{access_control_params}"
          expect(page).to have_selector("h1", text: "Your planning application")

          within "#replacement-document-validation-requests" do
            expect(page).to have_selector("h3", text: "Provide replacement documents")
            expect(page).to have_selector("strong.govuk-tag--grey", text: "Not started")
            expect(page).to have_link("Upload proposed-floorplan.png", href: %r{\A/replacement_document_validation_requests/#{validation_request.id}/edit})
          end
        end
      end

      context "and the request is cancelled" do
        let(:validation_request_status) { :cancelled }

        it "shows the request in the list and its status" do
          visit "/validation_requests?#{access_control_params}"
          expect(page).to have_selector("h1", text: "Your planning application")

          within "#replacement-document-validation-requests" do
            expect(page).to have_selector("h3", text: "Provide replacement documents")
            expect(page).to have_selector("strong.govuk-tag--red", text: "Cancelled")
            expect(page).to have_link("Upload proposed-floorplan.png", href: %r{\A/replacement_document_validation_requests/#{validation_request.id}})
          end
        end
      end

      context "and the request is closed" do
        let(:validation_request_status) { :closed }

        it "shows the request in the list and its status" do
          visit "/validation_requests?#{access_control_params}"
          expect(page).to have_selector("h1", text: "Your planning application")

          within "#replacement-document-validation-requests" do
            expect(page).to have_selector("h3", text: "Provide replacement documents")
            expect(page).to have_selector("strong.govuk-tag--green", text: "Complete")
            expect(page).to have_link("Upload proposed-floorplan.png", href: %r{\A/replacement_document_validation_requests/#{validation_request.id}})
          end
        end
      end
    end

    context "and it has a request to upload additional documents" do
      let!(:validation_request) do
        create(:additional_document_validation_request, validation_request_status, planning_application:)
      end

      context "and the request is open" do
        let(:validation_request_status) { :open }

        it "shows the request in the list and its status" do
          visit "/validation_requests?#{access_control_params}"
          expect(page).to have_selector("h1", text: "Your planning application")

          within "#additional-document-validation-requests" do
            expect(page).to have_selector("h3", text: "Provide new or missing documents")
            expect(page).to have_selector("strong.govuk-tag--grey", text: "Not started")
            expect(page).to have_link("Upload new document", href: %r{\A/additional_document_validation_requests/#{validation_request.id}/edit})
          end
        end
      end

      context "and the request is cancelled" do
        let(:validation_request_status) { :cancelled }

        it "shows the request in the list and its status" do
          visit "/validation_requests?#{access_control_params}"
          expect(page).to have_selector("h1", text: "Your planning application")

          within "#additional-document-validation-requests" do
            expect(page).to have_selector("h3", text: "Provide new or missing documents")
            expect(page).to have_selector("strong.govuk-tag--red", text: "Cancelled")
            expect(page).to have_link("Upload new document", href: %r{\A/additional_document_validation_requests/#{validation_request.id}})
          end
        end
      end

      context "and the request is closed" do
        let(:validation_request_status) { :closed }

        it "shows the request in the list and its status" do
          visit "/validation_requests?#{access_control_params}"
          expect(page).to have_selector("h1", text: "Your planning application")

          within "#additional-document-validation-requests" do
            expect(page).to have_selector("h3", text: "Provide new or missing documents")
            expect(page).to have_selector("strong.govuk-tag--green", text: "Complete")
            expect(page).to have_link("Upload new document", href: %r{\A/additional_document_validation_requests/#{validation_request.id}})
          end
        end
      end
    end

    context "and it has a request to change the red line boundary" do
      let!(:validation_request) do
        create(:red_line_boundary_change_validation_request, validation_request_status, planning_application:)
      end

      context "and the request is open" do
        let(:validation_request_status) { :open }

        it "shows the request in the list and its status" do
          visit "/validation_requests?#{access_control_params}"
          expect(page).to have_selector("h1", text: "Your planning application")

          within "#red-line-boundary-change-validation-requests" do
            expect(page).to have_selector("h3", text: "Confirm changes to the red line boundary")
            expect(page).to have_selector("strong.govuk-tag--grey", text: "Not started")
            expect(page).to have_link("Check red line boundary", href: %r{\A/red_line_boundary_change_validation_requests/#{validation_request.id}/edit})
          end
        end
      end

      context "and the request is cancelled" do
        let(:validation_request_status) { :cancelled }

        it "shows the request in the list and its status" do
          visit "/validation_requests?#{access_control_params}"
          expect(page).to have_selector("h1", text: "Your planning application")

          within "#red-line-boundary-change-validation-requests" do
            expect(page).to have_selector("h3", text: "Confirm changes to the red line boundary")
            expect(page).to have_selector("strong.govuk-tag--red", text: "Cancelled")
            expect(page).to have_link("Check red line boundary", href: %r{\A/red_line_boundary_change_validation_requests/#{validation_request.id}})
          end
        end
      end

      context "and the request is closed" do
        let(:validation_request_status) { :closed }

        it "shows the request in the list and its status" do
          visit "/validation_requests?#{access_control_params}"
          expect(page).to have_selector("h1", text: "Your planning application")

          within "#red-line-boundary-change-validation-requests" do
            expect(page).to have_selector("h3", text: "Confirm changes to the red line boundary")
            expect(page).to have_selector("strong.govuk-tag--green", text: "Complete")
            expect(page).to have_link("Check red line boundary", href: %r{\A/red_line_boundary_change_validation_requests/#{validation_request.id}})
          end
        end
      end
    end

    context "and it has a request to change the application fee" do
      let!(:validation_request) do
        create(:fee_change_validation_request, validation_request_status, planning_application:)
      end

      context "and the request is open" do
        let(:validation_request_status) { :open }

        it "shows the request in the list and its status" do
          visit "/validation_requests?#{access_control_params}"
          expect(page).to have_selector("h1", text: "Your planning application")

          within "#fee-change-validation-requests" do
            expect(page).to have_selector("h3", text: "Respond to fee change request")
            expect(page).to have_selector("strong.govuk-tag--grey", text: "Not started")
            expect(page).to have_link("Check fee", href: %r{\A/fee_change_validation_requests/#{validation_request.id}/edit})
          end
        end
      end

      context "and the request is cancelled" do
        let(:validation_request_status) { :cancelled }

        it "shows the request in the list and its status" do
          visit "/validation_requests?#{access_control_params}"
          expect(page).to have_selector("h1", text: "Your planning application")

          within "#fee-change-validation-requests" do
            expect(page).to have_selector("h3", text: "Respond to fee change request")
            expect(page).to have_selector("strong.govuk-tag--red", text: "Cancelled")
            expect(page).to have_link("Check fee", href: %r{\A/fee_change_validation_requests/#{validation_request.id}})
          end
        end
      end

      context "and the request is closed" do
        let(:validation_request_status) { :closed }

        it "shows the request in the list and its status" do
          visit "/validation_requests?#{access_control_params}"
          expect(page).to have_selector("h1", text: "Your planning application")

          within "#fee-change-validation-requests" do
            expect(page).to have_selector("h3", text: "Respond to fee change request")
            expect(page).to have_selector("strong.govuk-tag--green", text: "Complete")
            expect(page).to have_link("Check fee", href: %r{\A/fee_change_validation_requests/#{validation_request.id}})
          end
        end
      end
    end

    context "and it has a request to confirm ownership" do
      let!(:validation_request) do
        create(:ownership_certificate_validation_request, validation_request_status, planning_application:)
      end

      context "and the request is open" do
        let(:validation_request_status) { :open }

        it "shows the request in the list and its status" do
          visit "/validation_requests?#{access_control_params}"
          expect(page).to have_selector("h1", text: "Your planning application")

          within "#ownership-certificate-validation-requests" do
            expect(page).to have_selector("h3", text: "Confirm ownership of the land")
            expect(page).to have_selector("strong.govuk-tag--grey", text: "Not started")
            expect(page).to have_link("Confirm ownership", href: %r{\A/ownership_certificate_validation_requests/#{validation_request.id}/edit})
          end
        end
      end

      context "and the request is cancelled" do
        let(:validation_request_status) { :cancelled }

        it "shows the request in the list and its status" do
          visit "/validation_requests?#{access_control_params}"
          expect(page).to have_selector("h1", text: "Your planning application")

          within "#ownership-certificate-validation-requests" do
            expect(page).to have_selector("h3", text: "Confirm ownership of the land")
            expect(page).to have_selector("strong.govuk-tag--red", text: "Cancelled")
            expect(page).to have_link("Confirm ownership", href: %r{\A/ownership_certificate_validation_requests/#{validation_request.id}})
          end
        end
      end

      context "and the request is closed" do
        let(:validation_request_status) { :closed }

        it "shows the request in the list and its status" do
          visit "/validation_requests?#{access_control_params}"
          expect(page).to have_selector("h1", text: "Your planning application")

          within "#ownership-certificate-validation-requests" do
            expect(page).to have_selector("h3", text: "Confirm ownership of the land")
            expect(page).to have_selector("strong.govuk-tag--green", text: "Complete")
            expect(page).to have_link("Confirm ownership", href: %r{\A/ownership_certificate_validation_requests/#{validation_request.id}})
          end
        end
      end
    end

    context "and it has a request to change other things" do
      let!(:validation_request) do
        create(:other_change_validation_request, validation_request_status, planning_application:)
      end

      context "and the request is open" do
        let(:validation_request_status) { :open }

        it "shows the request in the list and its status" do
          visit "/validation_requests?#{access_control_params}"
          expect(page).to have_selector("h1", text: "Your planning application")

          within "#other-change-validation-requests" do
            expect(page).to have_selector("h3", text: "Respond to other requests")
            expect(page).to have_selector("strong.govuk-tag--grey", text: "Not started")
            expect(page).to have_link("View other request", href: %r{\A/other_change_validation_requests/#{validation_request.id}/edit})
          end
        end
      end

      context "and the request is cancelled" do
        let(:validation_request_status) { :cancelled }

        it "shows the request in the list and its status" do
          visit "/validation_requests?#{access_control_params}"
          expect(page).to have_selector("h1", text: "Your planning application")

          within "#other-change-validation-requests" do
            expect(page).to have_selector("h3", text: "Respond to other requests")
            expect(page).to have_selector("strong.govuk-tag--red", text: "Cancelled")
            expect(page).to have_link("View other request", href: %r{\A/other_change_validation_requests/#{validation_request.id}})
          end
        end
      end

      context "and the request is closed" do
        let(:validation_request_status) { :closed }

        it "shows the request in the list and its status" do
          visit "/validation_requests?#{access_control_params}"
          expect(page).to have_selector("h1", text: "Your planning application")

          within "#other-change-validation-requests" do
            expect(page).to have_selector("h3", text: "Respond to other requests")
            expect(page).to have_selector("strong.govuk-tag--green", text: "Complete")
            expect(page).to have_link("View other request", href: %r{\A/other_change_validation_requests/#{validation_request.id}})
          end
        end
      end
    end
  end

  context "when the application is in progress" do
    let(:planning_application_status) { :in_progress }

    before do
      allow(Current).to receive(:user).and_return(user)
    end

    context "and it has a request to agree pre-commencement conditions" do
      let!(:condition_set) { create(:condition_set, planning_application:, pre_commencement: true) }
      let!(:condition) { create(:condition, condition_set:, title: "Section 278 agreement") }
      let(:validation_request) { condition.current_validation_request }

      context "and the request is open" do
        before do
          validation_request.mark_as_sent!
        end

        it "shows the request in the list and its status" do
          visit "/validation_requests?#{access_control_params}"
          expect(page).to have_selector("h1", text: "Your planning application")

          within "#pre-commencement-condition-validation-requests" do
            expect(page).to have_selector("h3", text: "Respond to pre-commencement conditions")
            expect(page).to have_selector("strong.govuk-tag--grey", text: "Not started")
            expect(page).to have_link("Section 278 agreement", href: %r{\A/pre_commencement_condition_validation_requests/#{validation_request.id}/edit})
          end
        end
      end

      context "and the request is cancelled" do
        before do
          validation_request.cancel_reason = "Created in error"
          validation_request.cancel!
        end

        it "shows the request in the list and its status" do
          visit "/validation_requests?#{access_control_params}"
          expect(page).to have_selector("h1", text: "Your planning application")

          within "#pre-commencement-condition-validation-requests" do
            expect(page).to have_selector("h3", text: "Respond to pre-commencement conditions")
            expect(page).to have_selector("strong.govuk-tag--red", text: "Cancelled")
            expect(page).to have_link("Section 278 agreement", href: %r{\A/pre_commencement_condition_validation_requests/#{validation_request.id}})
          end
        end
      end

      context "and the request is closed" do
        before do
          validation_request.mark_as_sent!
          validation_request.close!
        end

        it "shows the request in the list and its status" do
          visit "/validation_requests?#{access_control_params}"
          expect(page).to have_selector("h1", text: "Your planning application")

          within "#pre-commencement-condition-validation-requests" do
            expect(page).to have_selector("h3", text: "Respond to pre-commencement conditions")
            expect(page).to have_selector("strong.govuk-tag--green", text: "Complete")
            expect(page).to have_link("Section 278 agreement", href: %r{\A/pre_commencement_condition_validation_requests/#{validation_request.id}})
          end
        end
      end
    end

    context "and it has a request to agree heads of terms" do
      let!(:heads_of_term) { create(:heads_of_term, planning_application:) }
      let!(:term) { create(:term, :skip_validation_request, heads_of_term:, title: "Section 106 agreement") }

      context "and the request is open" do
        let!(:validation_request) { create(:heads_of_terms_validation_request, planning_application:, state: "open", owner: term) }

        it "shows the request in the list and its status" do
          visit "/validation_requests?#{access_control_params}"
          expect(page).to have_selector("h1", text: "Your planning application")

          within "#heads-of-terms-validation-requests" do
            expect(page).to have_selector("h3", text: "Respond to heads of terms")
            expect(page).to have_selector("strong.govuk-tag--grey", text: "Not started")
            expect(page).to have_link("Section 106 agreement", href: %r{\A/heads_of_terms_validation_requests/#{validation_request.id}/edit})
          end
        end
      end

      context "and the request is cancelled" do
        let!(:validation_request) { create(:heads_of_terms_validation_request, planning_application:, state: "cancelled", cancel_reason: "Created in error", owner: term) }

        it "shows the request in the list and its status" do
          visit "/validation_requests?#{access_control_params}"
          expect(page).to have_selector("h1", text: "Your planning application")

          within "#heads-of-terms-validation-requests" do
            expect(page).to have_selector("h3", text: "Respond to heads of terms")
            expect(page).to have_selector("strong.govuk-tag--red", text: "Cancelled")
            expect(page).to have_link("Section 106 agreement", href: %r{\A/heads_of_terms_validation_requests/#{validation_request.id}})
          end
        end
      end

      context "and the request is closed" do
        let!(:validation_request) { create(:heads_of_terms_validation_request, planning_application:, state: "closed", owner: term) }

        it "shows the request in the list and its status" do
          visit "/validation_requests?#{access_control_params}"
          expect(page).to have_selector("h1", text: "Your planning application")

          within "#heads-of-terms-validation-requests" do
            expect(page).to have_selector("h3", text: "Respond to heads of terms")
            expect(page).to have_selector("strong.govuk-tag--green", text: "Complete")
            expect(page).to have_link("Section 106 agreement", href: %r{\A/heads_of_terms_validation_requests/#{validation_request.id}})
          end
        end
      end
    end
  end
end
