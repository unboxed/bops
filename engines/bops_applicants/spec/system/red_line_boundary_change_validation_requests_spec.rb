# frozen_string_literal: true

require "bops_applicants_helper"

RSpec.describe "Red line boundary change validation requests" do
  let!(:local_authority) { create(:local_authority, :default) }
  let!(:user) { create(:user, :assessor, local_authority:) }

  let!(:existing_geojson) do
    <<~JSON
      {
        "type": "Feature",
        "properties": {},
        "geometry": {
          "type": "Polygon",
          "coordinates": [
            [
              [-0.054597, 51.537331],
              [-0.054588, 51.537287],
              [-0.054453, 51.537313],
              [-0.054597, 51.537331]
            ]
          ]
        }
      }
    JSON
  end

  let!(:new_geojson) do
    <<~JSON
      {
        "type": "Feature",
        "properties": {},
        "geometry": {
          "type": "Polygon",
          "coordinates": [
            [
              [-0.077161, 51.500942],
              [-0.076459, 51.500534],
              [-0.076153, 51.501152],
              [-0.077161, 51.500942]
            ]
          ]
        }
      }
    JSON
  end

  let!(:existing_boundary) { JSON.parse(existing_geojson) }
  let!(:new_boundary) { JSON.parse(new_geojson) }

  let(:planning_application) do
    create(
      :planning_application,
      :planning_permission,
      :invalidated,
      local_authority: local_authority,
      description: "Application for the erection of 47 dwellings",
      address_1: "60-62 Commercial Street",
      town: "London",
      postcode: "E1 6LT",
      boundary_geojson: existing_boundary
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
        visit "/red_line_boundary_change_validation_requests/123"
      }.to raise_error(BopsCore::Errors::NotFoundError)
    end
  end

  context "when a validation request exists" do
    let!(:validation_request) do
      create(
        :red_line_boundary_change_validation_request,
        validation_request_status,
        planning_application:,
        reason: "The submitted boundary is incorrect",
        approved: validation_request_approved,
        rejection_reason: validation_request_rejection_reason,
        specific_attributes: {new_geojson: new_boundary}
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
            visit "/red_line_boundary_change_validation_requests/#{validation_request.id}?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end

        it "returns an error page for the edit action" do
          expect {
            visit "/red_line_boundary_change_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end
      end

      context "and the access control parameters present" do
        it "returns an error page for the show action" do
          expect {
            visit "/red_line_boundary_change_validation_requests/#{validation_request.id}?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end

        it "can be agreed with" do
          visit "/red_line_boundary_change_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
          expect(page).to have_selector("h1", text: "Confirm changes to your application’s red line boundary")
          expect(page).to have_content("If your response is not received by 16 June 2025")

          within "#red-line-boundary-change-reason" do
            expect(page).to have_selector("h3", text: "Reason change is requested")
            expect(page).to have_content("The submitted boundary is incorrect")
          end

          within "#red-line-boundary-change-original" do
            expect(page).to have_selector("h3", text: "Your original red line boundary")
            expect(page).to have_selector("my-map")
          end

          within "#red-line-boundary-change-proposed" do
            expect(page).to have_selector("h3", text: "Proposed red line boundary")
            expect(page).to have_selector("my-map")
          end

          click_button "Submit"
          expect(page).to have_selector("[role=alert] p", text: "There was a problem sending your response to the case officer")
          expect(page).to have_link("check the form below", href: "#validation-request-form")
          expect(page).to have_content("Tell us whether you agree or disagree with the proposed red line boundary")

          choose "Yes, I agree with the proposed red line boundary"

          expect {
            click_button "Submit"
            expect(page).to have_selector("h1", text: "Your planning application")
            expect(page).to have_selector("[role=alert] p", text: "Your response has been sent to the case officer")
          }.to change {
            planning_application.reload.boundary_geojson
          }.from(existing_boundary).to(new_boundary)

          within "#red-line-boundary-change-validation-requests" do
            expect(page).to have_selector("h3", text: "Confirm changes to the red line boundary")
            expect(page).to have_selector("strong.govuk-tag--green", text: "Complete")
            expect(page).to have_link("Check red line boundary", href: %r{\A/red_line_boundary_change_validation_requests/#{validation_request.id}})

            click_link "Check red line boundary"
          end

          expect(page).to have_selector("h1", text: "Confirm changes to your red line boundary")

          within "#red-line-boundary-change-original" do
            expect(page).to have_selector("h2", text: "Your original red line boundary")
            expect(page).to have_selector("my-map")
          end

          within "#red-line-boundary-change-proposed" do
            expect(page).to have_selector("h2", text: "Proposed red line boundary")
            expect(page).to have_selector("my-map")
          end

          within "#red-line-boundary-change-response" do
            expect(page).to have_content("Agreed with suggested boundary changes")
          end
        end

        it "can be disagreed with" do
          visit "/red_line_boundary_change_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
          expect(page).to have_selector("h1", text: "Confirm changes to your application’s red line boundary")
          expect(page).to have_content("If your response is not received by 16 June 2025")

          within "#red-line-boundary-change-reason" do
            expect(page).to have_selector("h3", text: "Reason change is requested")
            expect(page).to have_content("The submitted boundary is incorrect")
          end

          within "#red-line-boundary-change-original" do
            expect(page).to have_selector("h3", text: "Your original red line boundary")
            expect(page).to have_selector("my-map")
          end

          within "#red-line-boundary-change-proposed" do
            expect(page).to have_selector("h3", text: "Proposed red line boundary")
            expect(page).to have_selector("my-map")
          end

          choose "No, I disagree with the proposed red line boundary"

          click_button "Submit"
          expect(page).to have_selector("[role=alert] p", text: "There was a problem sending your response to the case officer")
          expect(page).to have_link("check the form below", href: "#validation-request-form")
          expect(page).to have_content("Tell us why you disagree with the proposed red line boundary")

          fill_in "Indicate why you disagree", with: "The original red line boundary is correct"

          expect {
            click_button "Submit"
            expect(page).to have_selector("h1", text: "Your planning application")
            expect(page).to have_selector("[role=alert] p", text: "Your response has been sent to the case officer")
          }.not_to change {
            planning_application.reload.boundary_geojson
          }.from(existing_boundary)

          within "#red-line-boundary-change-validation-requests" do
            expect(page).to have_selector("h3", text: "Confirm changes to the red line boundary")
            expect(page).to have_selector("strong.govuk-tag--green", text: "Complete")
            expect(page).to have_link("Check red line boundary", href: %r{\A/red_line_boundary_change_validation_requests/#{validation_request.id}})

            click_link "Check red line boundary"
          end

          expect(page).to have_selector("h1", text: "Confirm changes to your red line boundary")

          within "#red-line-boundary-change-original" do
            expect(page).to have_selector("h2", text: "Your original red line boundary")
            expect(page).to have_selector("my-map")
          end

          within "#red-line-boundary-change-proposed" do
            expect(page).to have_selector("h2", text: "Proposed red line boundary")
            expect(page).to have_selector("my-map")
          end

          within "#red-line-boundary-change-response" do
            expect(page).to have_content("Disagreed with suggested boundary changes")
            expect(page).to have_content("The original red line boundary is correct")
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
            visit "/red_line_boundary_change_validation_requests/#{validation_request.id}?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end

        it "returns an error page for the edit action" do
          expect {
            visit "/red_line_boundary_change_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end
      end

      context "and the access control parameters present" do
        it "shows the reason for the cancellation" do
          visit "/red_line_boundary_change_validation_requests/#{validation_request.id}?#{access_control_params}"
          expect(page).to have_selector("h1", text: "Cancelled request to change your application’s red line boundary")

          within "#cancellation-reason" do
            expect(page).to have_content("Made by mistake!")
            expect(page).to have_content("23 May 2025 13:00")
          end
        end

        it "returns an error page for the edit action" do
          expect {
            visit "/red_line_boundary_change_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
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
            visit "/red_line_boundary_change_validation_requests/#{validation_request.id}?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end

        it "returns an error page for the edit action" do
          expect {
            visit "/red_line_boundary_change_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end
      end

      context "and the access control parameters present" do
        context "and the request was approved" do
          let(:validation_request_approved) { true }
          let(:validation_request_rejection_reason) { nil }

          it "shows the response" do
            visit "/red_line_boundary_change_validation_requests/#{validation_request.id}?#{access_control_params}"
            expect(page).to have_selector("h1", text: "Confirm changes to your red line boundary")

            within "#red-line-boundary-change-original" do
              expect(page).to have_selector("h2", text: "Your original red line boundary")
              expect(page).to have_selector("my-map")
            end

            within "#red-line-boundary-change-proposed" do
              expect(page).to have_selector("h2", text: "Proposed red line boundary")
              expect(page).to have_selector("my-map")
            end

            within "#red-line-boundary-change-response" do
              expect(page).to have_content("Agreed with suggested boundary changes")
            end
          end
        end

        context "and the request was rejected" do
          let(:validation_request_approved) { false }
          let(:validation_request_rejection_reason) { "The original red line boundary is correct" }

          it "shows the response" do
            visit "/red_line_boundary_change_validation_requests/#{validation_request.id}?#{access_control_params}"
            expect(page).to have_selector("h1", text: "Confirm changes to your red line boundary")

            within "#red-line-boundary-change-original" do
              expect(page).to have_selector("h2", text: "Your original red line boundary")
              expect(page).to have_selector("my-map")
            end

            within "#red-line-boundary-change-proposed" do
              expect(page).to have_selector("h2", text: "Proposed red line boundary")
              expect(page).to have_selector("my-map")
            end

            within "#red-line-boundary-change-response" do
              expect(page).to have_content("Disagreed with suggested boundary changes")
              expect(page).to have_content("The original red line boundary is correct")
            end
          end
        end

        it "returns an error page for the edit action" do
          expect {
            visit "/red_line_boundary_change_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end
      end
    end
  end
end
