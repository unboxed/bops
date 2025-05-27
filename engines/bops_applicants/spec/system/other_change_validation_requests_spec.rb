# frozen_string_literal: true

require "bops_applicants_helper"

RSpec.describe "Other change validation requests" do
  let!(:local_authority) { create(:local_authority, :default) }
  let!(:user) { create(:user, :assessor, local_authority:) }

  let(:planning_application) do
    create(
      :planning_application,
      :planning_permission,
      :invalidated,
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

  context "when a validation request doesn't exist" do
    it "returns an error page" do
      expect {
        visit "/other_change_validation_requests/123"
      }.to raise_error(BopsCore::Errors::NotFoundError)
    end
  end

  context "when a validation request exists" do
    let!(:validation_request) do
      create(
        :other_change_validation_request,
        validation_request_status,
        planning_application:,
        reason: "The biodiversity section is missing",
        response: validation_request_response,
        specific_attributes: {
          suggestion: "You'll have to withdraw the application and resubmit"
        }
      )
    end

    context "and the request is open" do
      let(:validation_request_status) { :open }
      let(:validation_request_response) { nil }

      context "and the access control parameters are missing" do
        let(:access_control_params) { "" }

        it "returns an error page for the show action" do
          expect {
            visit "/other_change_validation_requests/#{validation_request.id}?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end

        it "returns an error page for the edit action" do
          expect {
            visit "/other_change_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end
      end

      context "and the access control parameters present" do
        it "returns an error page for the show action" do
          expect {
            visit "/other_change_validation_requests/#{validation_request.id}?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end

        it "can be responded to" do
          visit "/other_change_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
          expect(page).to have_selector("h1", text: "Respond to other request")
          expect(page).to have_content("You must submit your response by 16 June 2025")

          within "#other-change-reason" do
            expect(page).to have_content("The biodiversity section is missing")
          end

          within "#other-change-suggestion" do
            expect(page).to have_content("You'll have to withdraw the application and resubmit")
          end

          click_button "Submit"
          expect(page).to have_selector("[role=alert] p", text: "There was a problem sending your response to the case officer")
          expect(page).to have_link("check the form below", href: "#validation-request-form")
          expect(page).to have_content("Tell us how you plan to make your application valid")

          fill_in "Respond to this request", with: "I will withdraw the application and resubmit"

          click_button "Submit"
          expect(page).to have_selector("h1", text: "Your planning application")
          expect(page).to have_selector("[role=alert] p", text: "Your response has been sent to the case officer")

          within "#other-change-validation-requests" do
            expect(page).to have_selector("h3", text: "Respond to other requests")
            expect(page).to have_selector("strong.govuk-tag--green", text: "Complete")
            expect(page).to have_link("View other request", href: %r{\A/other_change_validation_requests/#{validation_request.id}})

            click_link "View other request"
          end

          expect(page).to have_selector("h1", text: "Response to other validation change request")

          within "#other-change-reason" do
            expect(page).to have_content("The biodiversity section is missing")
          end

          within "#other-change-suggestion" do
            expect(page).to have_content("You'll have to withdraw the application and resubmit")
          end

          within "#other-change-response" do
            expect(page).to have_content("I will withdraw the application and resubmit")
          end
        end
      end
    end

    context "and the request is cancelled" do
      let(:validation_request_status) { :cancelled }
      let(:validation_request_response) { nil }

      context "and the access control parameters are missing" do
        let(:access_control_params) { "" }

        it "returns an error page for the show action" do
          expect {
            visit "/other_change_validation_requests/#{validation_request.id}?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end

        it "returns an error page for the edit action" do
          expect {
            visit "/other_change_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end
      end

      context "and the access control parameters present" do
        it "shows the reason for the cancellation" do
          visit "/other_change_validation_requests/#{validation_request.id}?#{access_control_params}"
          expect(page).to have_selector("h1", text: "Cancelled other request to change your application")

          within "#cancellation-reason" do
            expect(page).to have_content("Made by mistake!")
            expect(page).to have_content("23 May 2025 13:00")
          end
        end

        it "returns an error page for the edit action" do
          expect {
            visit "/other_change_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end
      end
    end

    context "and the request is closed" do
      let(:validation_request_status) { :closed }
      let(:validation_request_response) { "I will withdraw the application and resubmit" }

      context "and the access control parameters are missing" do
        let(:access_control_params) { "" }

        it "returns an error page for the show action" do
          expect {
            visit "/other_change_validation_requests/#{validation_request.id}?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end

        it "returns an error page for the edit action" do
          expect {
            visit "/other_change_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end
      end

      context "and the access control parameters present" do
        it "shows the response" do
          visit "/other_change_validation_requests/#{validation_request.id}?#{access_control_params}"
          expect(page).to have_selector("h1", text: "Response to other validation change request")

          within "#other-change-reason" do
            expect(page).to have_content("The biodiversity section is missing")
          end

          within "#other-change-suggestion" do
            expect(page).to have_content("You'll have to withdraw the application and resubmit")
          end

          within "#other-change-response" do
            expect(page).to have_content("I will withdraw the application and resubmit")
          end
        end

        it "returns an error page for the edit action" do
          expect {
            visit "/other_change_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end
      end
    end
  end
end
