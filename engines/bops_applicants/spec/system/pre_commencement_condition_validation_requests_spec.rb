# frozen_string_literal: true

require "bops_applicants_helper"

RSpec.describe "Pre-commencement condition validation requests" do
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

  before do
    allow(Current).to receive(:user).and_return(user)
  end

  around do |example|
    travel_to("2025-05-23T12:00:00Z") { example.run }
  end

  context "when a validation request doesn't exist" do
    it "returns an error page" do
      expect {
        visit "/pre_commencement_condition_validation_requests/123"
      }.to raise_error(BopsCore::Errors::NotFoundError)
    end
  end

  context "when a validation request exists" do
    let!(:condition_set) { create(:condition_set, planning_application:, pre_commencement: true) }

    let!(:condition) do
      create(
        :condition,
        condition_set:,
        title: "Section 278 agreement",
        text: "Build a new left-in, left-out junction on to the B1234",
        reason: "For the safety of the public on the highways"
      )
    end

    let(:validation_request) { condition.current_validation_request }

    before do
      validation_request.mark_as_sent!
    end

    context "and the request is open" do
      context "and the access control parameters are missing" do
        let(:access_control_params) { "" }

        it "returns an error page for the show action" do
          expect {
            visit "/pre_commencement_condition_validation_requests/#{validation_request.id}?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end

        it "returns an error page for the edit action" do
          expect {
            visit "/pre_commencement_condition_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end
      end

      context "and the access control parameters present" do
        it "returns an error page for the show action" do
          expect {
            visit "/pre_commencement_condition_validation_requests/#{validation_request.id}?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end

        it "can be accepted" do
          visit "/pre_commencement_condition_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
          expect(page).to have_selector("h1", text: "Review pre-commencement condition")

          within "#pre-commencement-condition-suggestion" do
            expect(page).to have_selector("h3", text: "Condition: Section 278 agreement")
            expect(page).to have_content("Build a new left-in, left-out junction on to the B1234")
          end

          within "#pre-commencement-condition-reason" do
            expect(page).to have_selector("h3", text: "Reason")
            expect(page).to have_content("For the safety of the public on the highways")
          end

          click_button "Submit"
          expect(page).to have_selector("[role=alert] p", text: "There was a problem sending your response to the case officer")
          expect(page).to have_link("check the form below", href: "#validation-request-form")
          expect(page).to have_content("Tell us whether you accept or do not accept this condition")

          choose "I accept the condition"

          click_button "Submit"
          expect(page).to have_selector("h1", text: "Your planning application")
          expect(page).to have_selector("[role=alert] p", text: "Your response has been sent to the case officer")

          within "#pre-commencement-condition-validation-requests" do
            expect(page).to have_selector("h3", text: "Respond to pre-commencement conditions")
            expect(page).to have_selector("strong.govuk-tag--green", text: "Complete")
            expect(page).to have_link("Section 278 agreement", href: %r{\A/pre_commencement_condition_validation_requests/#{validation_request.id}})

            click_link "Section 278 agreement"
          end

          expect(page).to have_selector("h1", text: "Review pre-commencement condition")

          within "#pre-commencement-condition-suggestion" do
            expect(page).to have_selector("h2", text: "Condition: Section 278 agreement")
            expect(page).to have_content("Build a new left-in, left-out junction on to the B1234")
          end

          within "#pre-commencement-condition-reason" do
            expect(page).to have_selector("h2", text: "Reason")
            expect(page).to have_content("For the safety of the public on the highways")
          end

          within "#pre-commencement-condition-response" do
            expect(page).to have_content("Agreed to the condition")
          end
        end

        it "can be not accepted with" do
          visit "/pre_commencement_condition_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
          expect(page).to have_selector("h1", text: "Review pre-commencement condition")

          within "#pre-commencement-condition-suggestion" do
            expect(page).to have_selector("h3", text: "Condition: Section 278 agreement")
            expect(page).to have_content("Build a new left-in, left-out junction on to the B1234")
          end

          within "#pre-commencement-condition-reason" do
            expect(page).to have_selector("h3", text: "Reason")
            expect(page).to have_content("For the safety of the public on the highways")
          end

          choose "I do not accept the condition"

          click_button "Submit"
          expect(page).to have_selector("[role=alert] p", text: "There was a problem sending your response to the case officer")
          expect(page).to have_link("check the form below", href: "#validation-request-form")
          expect(page).to have_content("Tell us why you do not accept this condition")

          fill_in "Tell us why you do not accept this condition", with: "The cost makes the proposal uneconomic"

          click_button "Submit"
          expect(page).to have_selector("h1", text: "Your planning application")
          expect(page).to have_selector("[role=alert] p", text: "Your response has been sent to the case officer")

          within "#pre-commencement-condition-validation-requests" do
            expect(page).to have_selector("h3", text: "Respond to pre-commencement conditions")
            expect(page).to have_selector("strong.govuk-tag--green", text: "Complete")
            expect(page).to have_link("Section 278 agreement", href: %r{\A/pre_commencement_condition_validation_requests/#{validation_request.id}})

            click_link "Section 278 agreement"
          end

          expect(page).to have_selector("h1", text: "Review pre-commencement condition")

          within "#pre-commencement-condition-suggestion" do
            expect(page).to have_selector("h2", text: "Condition: Section 278 agreement")
            expect(page).to have_content("Build a new left-in, left-out junction on to the B1234")
          end

          within "#pre-commencement-condition-reason" do
            expect(page).to have_selector("h2", text: "Reason")
            expect(page).to have_content("For the safety of the public on the highways")
          end

          within "#pre-commencement-condition-response" do
            expect(page).to have_content("Disagreed with the condition")
            expect(page).to have_content("The cost makes the proposal uneconomic")
          end
        end
      end
    end

    context "and the request is cancelled" do
      before do
        validation_request.cancel_reason = "Made by mistake!"
        validation_request.cancelled_at = Time.current
        validation_request.cancel!
      end

      context "and the access control parameters are missing" do
        let(:access_control_params) { "" }

        it "returns an error page for the show action" do
          expect {
            visit "/pre_commencement_condition_validation_requests/#{validation_request.id}?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end

        it "returns an error page for the edit action" do
          expect {
            visit "/pre_commencement_condition_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end
      end

      context "and the access control parameters present" do
        it "shows the reason for the cancellation" do
          visit "/pre_commencement_condition_validation_requests/#{validation_request.id}?#{access_control_params}"
          expect(page).to have_selector("h1", text: "Cancelled pre-commencement condition request for your application")

          within "#cancellation-reason" do
            expect(page).to have_content("Made by mistake!")
            expect(page).to have_content("23 May 2025 13:00")
          end
        end

        it "returns an error page for the edit action" do
          expect {
            visit "/pre_commencement_condition_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end
      end
    end

    context "and the request is closed" do
      let(:validation_request_params) do
        {approved: true}
      end

      before do
        validation_request.update!(validation_request_params)
        validation_request.close!
      end

      context "and the access control parameters are missing" do
        let(:access_control_params) { "" }

        it "returns an error page for the show action" do
          expect {
            visit "/pre_commencement_condition_validation_requests/#{validation_request.id}?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end

        it "returns an error page for the edit action" do
          expect {
            visit "/pre_commencement_condition_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end
      end

      context "and the access control parameters present" do
        context "and the request was approved" do
          it "shows the response" do
            visit "/pre_commencement_condition_validation_requests/#{validation_request.id}?#{access_control_params}"
            expect(page).to have_selector("h1", text: "Review pre-commencement condition")

            within "#pre-commencement-condition-suggestion" do
              expect(page).to have_selector("h2", text: "Condition: Section 278 agreement")
              expect(page).to have_content("Build a new left-in, left-out junction on to the B1234")
            end

            within "#pre-commencement-condition-reason" do
              expect(page).to have_selector("h2", text: "Reason")
              expect(page).to have_content("For the safety of the public on the highways")
            end

            within "#pre-commencement-condition-response" do
              expect(page).to have_content("Agreed to the condition")
            end
          end
        end

        context "and the request was rejected" do
          let(:validation_request_params) do
            {approved: false, rejection_reason: "The cost makes the proposal uneconomic"}
          end

          it "shows the response" do
            visit "/pre_commencement_condition_validation_requests/#{validation_request.id}?#{access_control_params}"
            expect(page).to have_selector("h1", text: "Review pre-commencement condition")

            within "#pre-commencement-condition-suggestion" do
              expect(page).to have_selector("h2", text: "Condition: Section 278 agreement")
              expect(page).to have_content("Build a new left-in, left-out junction on to the B1234")
            end

            within "#pre-commencement-condition-reason" do
              expect(page).to have_selector("h2", text: "Reason")
              expect(page).to have_content("For the safety of the public on the highways")
            end

            within "#pre-commencement-condition-response" do
              expect(page).to have_content("Disagreed with the condition")
              expect(page).to have_content("The cost makes the proposal uneconomic")
            end
          end
        end

        it "returns an error page for the edit action" do
          expect {
            visit "/pre_commencement_condition_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end
      end
    end
  end
end
