# frozen_string_literal: true

require "bops_applicants_helper"

RSpec.describe "Heads of term validation requests" do
  let!(:local_authority) { create(:local_authority, :default) }
  let!(:user) { create(:user, :assessor, local_authority:) }

  let(:planning_application) do
    create(
      :planning_application,
      :planning_permission,
      :in_assessment,
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
        visit "/heads_of_terms_validation_requests/123"
      }.to raise_error(BopsCore::Errors::NotFoundError)
    end
  end

  context "when a validation request exists" do
    let!(:heads_of_term) { create(:heads_of_term, planning_application:) }

    let!(:term) do
      create(
        :term,
        :skip_validation_request,
        heads_of_term:,
        title: "Section 106 agreement",
        text: "Installation of a MUGA pitch"
      )
    end

    let!(:validation_request) do
      create(
        :heads_of_terms_validation_request,
        validation_request_status,
        planning_application:,
        approved: validation_request_approved,
        rejection_reason: validation_request_rejection_reason,
        owner: term
      )
    end

    context "and the request is open" do
      let(:validation_request_status) { :open }
      let(:validation_request_approved) { nil }
      let(:validation_request_rejection_reason) { nil }

      context "and the access control parameters are missing" do
        let(:access_control_params) { "" }

        it "returns an error page for the show action" do
          expect {
            visit "/heads_of_terms_validation_requests/#{validation_request.id}?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end

        it "returns an error page for the edit action" do
          expect {
            visit "/heads_of_terms_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end
      end

      context "and the access control parameters present" do
        it "returns an error page for the show action" do
          expect {
            visit "/heads_of_terms_validation_requests/#{validation_request.id}?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end

        it "can be agreed with" do
          visit "/heads_of_terms_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
          expect(page).to have_selector("h1", text: "Respond to heads of terms request")

          within "#heads-of-terms-suggestion" do
            expect(page).to have_selector("h3", text: "Heads of term: Section 106 agreement")
            expect(page).to have_content("Installation of a MUGA pitch")
          end

          click_button "Submit"
          expect(page).to have_selector("[role=alert] p", text: "There was a problem sending your response to the case officer")
          expect(page).to have_link("check the form below", href: "#validation-request-form")
          expect(page).to have_content("Tell us whether you agree or disagree with the term")

          choose "Yes, I agree with the term"

          click_button "Submit"
          expect(page).to have_selector("h1", text: "Your planning application")
          expect(page).to have_selector("[role=alert] p", text: "Your response has been sent to the case officer")

          within "#heads-of-terms-validation-requests" do
            expect(page).to have_selector("h3", text: "Respond to heads of terms")
            expect(page).to have_selector("strong.govuk-tag--green", text: "Complete")
            expect(page).to have_link("Section 106 agreement", href: %r{\A/heads_of_terms_validation_requests/#{validation_request.id}})

            click_link "Section 106 agreement"
          end

          expect(page).to have_selector("h1", text: "Response to heads of terms validation change request")

          within "#heads-of-terms-suggestion" do
            expect(page).to have_selector("h2", text: "Heads of term: Section 106 agreement")
            expect(page).to have_content("Installation of a MUGA pitch")
          end

          within "#heads-of-terms-response" do
            expect(page).to have_content("Agreed to the term")
          end
        end

        it "can be disagreed with" do
          visit "/heads_of_terms_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
          expect(page).to have_selector("h1", text: "Respond to heads of terms request")

          within "#heads-of-terms-suggestion" do
            expect(page).to have_selector("h3", text: "Heads of term: Section 106 agreement")
            expect(page).to have_content("Installation of a MUGA pitch")
          end

          choose "No, I disagree with the term"

          click_button "Submit"
          expect(page).to have_selector("[role=alert] p", text: "There was a problem sending your response to the case officer")
          expect(page).to have_link("check the form below", href: "#validation-request-form")
          expect(page).to have_content("Tell us why you disagree with the term")

          fill_in "Tell us why you disagree", with: "The cost makes the proposal uneconomic"

          click_button "Submit"
          expect(page).to have_selector("h1", text: "Your planning application")
          expect(page).to have_selector("[role=alert] p", text: "Your response has been sent to the case officer")

          within "#heads-of-terms-validation-requests" do
            expect(page).to have_selector("h3", text: "Respond to heads of terms")
            expect(page).to have_selector("strong.govuk-tag--green", text: "Complete")
            expect(page).to have_link("Section 106 agreement", href: %r{\A/heads_of_terms_validation_requests/#{validation_request.id}})

            click_link "Section 106 agreement"
          end

          expect(page).to have_selector("h1", text: "Response to heads of terms validation change request")

          within "#heads-of-terms-suggestion" do
            expect(page).to have_selector("h2", text: "Heads of term: Section 106 agreement")
            expect(page).to have_content("Installation of a MUGA pitch")
          end

          within "#heads-of-terms-response" do
            expect(page).to have_content("Disagreed with the term")
            expect(page).to have_content("The cost makes the proposal uneconomic")
          end
        end
      end
    end

    context "and the request is cancelled" do
      let(:validation_request_status) { :cancelled }
      let(:validation_request_approved) { nil }
      let(:validation_request_rejection_reason) { nil }

      context "and the access control parameters are missing" do
        let(:access_control_params) { "" }

        it "returns an error page for the show action" do
          expect {
            visit "/heads_of_terms_validation_requests/#{validation_request.id}?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end

        it "returns an error page for the edit action" do
          expect {
            visit "/heads_of_terms_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end
      end

      context "and the access control parameters present" do
        it "shows the reason for the cancellation" do
          visit "/heads_of_terms_validation_requests/#{validation_request.id}?#{access_control_params}"
          expect(page).to have_selector("h1", text: "Cancelled heads of terms request for your application")

          within "#cancellation-reason" do
            expect(page).to have_content("Made by mistake!")
            expect(page).to have_content("23 May 2025 13:00")
          end
        end

        it "returns an error page for the edit action" do
          expect {
            visit "/heads_of_terms_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end
      end
    end

    context "and the request is closed" do
      let(:validation_request_status) { :closed }
      let(:validation_request_approved) { true }
      let(:validation_request_rejection_reason) { nil }

      context "and the access control parameters are missing" do
        let(:access_control_params) { "" }

        it "returns an error page for the show action" do
          expect {
            visit "/heads_of_terms_validation_requests/#{validation_request.id}?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end

        it "returns an error page for the edit action" do
          expect {
            visit "/heads_of_terms_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end
      end

      context "and the access control parameters present" do
        context "and the request was approved" do
          let(:validation_request_approved) { true }
          let(:validation_request_rejection_reason) { nil }

          it "shows the response" do
            visit "/heads_of_terms_validation_requests/#{validation_request.id}?#{access_control_params}"
            expect(page).to have_selector("h1", text: "Response to heads of terms validation change request")

            within "#heads-of-terms-suggestion" do
              expect(page).to have_selector("h2", text: "Heads of term: Section 106 agreement")
              expect(page).to have_content("Installation of a MUGA pitch")
            end

            within "#heads-of-terms-response" do
              expect(page).to have_content("Agreed to the term")
            end
          end
        end

        context "and the request was rejected" do
          let(:validation_request_approved) { false }
          let(:validation_request_rejection_reason) { "The cost makes the proposal uneconomic" }

          it "shows the response" do
            visit "/heads_of_terms_validation_requests/#{validation_request.id}?#{access_control_params}"
            expect(page).to have_selector("h1", text: "Response to heads of terms validation change request")

            within "#heads-of-terms-suggestion" do
              expect(page).to have_selector("h2", text: "Heads of term: Section 106 agreement")
              expect(page).to have_content("Installation of a MUGA pitch")
            end

            within "#heads-of-terms-response" do
              expect(page).to have_content("Disagreed with the term")
              expect(page).to have_content("The cost makes the proposal uneconomic")
            end
          end
        end

        it "returns an error page for the edit action" do
          expect {
            visit "/heads_of_terms_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end
      end
    end
  end
end
