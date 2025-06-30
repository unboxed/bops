# frozen_string_literal: true

require "bops_applicants_helper"

RSpec.describe "Fee change validation requests" do
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
        visit "/fee_change_validation_requests/123"
      }.to raise_error(BopsCore::Errors::NotFoundError)
    end
  end

  context "when a validation request exists" do
    let!(:validation_request) do
      create(
        :fee_change_validation_request,
        validation_request_status,
        planning_application:,
        reason: "Incorrect fee",
        response: validation_request_response,
        specific_attributes: {
          suggestion: "You need to pay a different fee"
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
            visit "/fee_change_validation_requests/#{validation_request.id}?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end

        it "returns an error page for the edit action" do
          expect {
            visit "/fee_change_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end
      end

      context "and the access control parameters present" do
        it "returns an error page for the show action" do
          expect {
            visit "/fee_change_validation_requests/#{validation_request.id}?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end

        it "can be responded to without documents" do
          visit "/fee_change_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
          expect(page).to have_selector("h1", text: "Provide evidence for fee concession or exemption")
          expect(page).to have_content("Send your response by 16 June 2025")

          within "#fee-change-reason" do
            expect(page).to have_selector("h3", text: "Comment from case officer")
            expect(page).to have_content("Incorrect fee")
          end

          within "#fee-change-suggestion" do
            expect(page).to have_selector("h3", text: "How to make your application valid")
            expect(page).to have_content("You need to pay a different fee")
          end

          click_button "Submit"
          expect(page).to have_selector("[role=alert] p", text: "There was a problem sending your response to the case officer")
          expect(page).to have_link("check the form below", href: "#validation-request-form")
          expect(page).to have_content("Tell us whether you agree or disagree with what was said")

          fill_in "Enter any comments", with: "I am eligible for a fee reduction"

          click_button "Submit"
          expect(page).to have_selector("h1", text: "Your planning application")
          expect(page).to have_selector("[role=alert] p", text: "Your response has been sent to the case officer")

          within "#fee-change-validation-requests" do
            expect(page).to have_selector("h3", text: "Respond to fee change request")
            expect(page).to have_selector("strong.govuk-tag--green", text: "Complete")
            expect(page).to have_link("Check fee", href: %r{\A/fee_change_validation_requests/#{validation_request.id}})

            click_link "Check fee"
          end

          expect(page).to have_selector("h1", text: "Response to fee change request")

          within "#fee-change-reason" do
            expect(page).to have_selector("h2", text: "Officer’s reason for invalidating application:")
            expect(page).to have_content("Incorrect fee")
          end

          within "#fee-change-suggestion" do
            expect(page).to have_selector("h2", text: "How you can make your application valid:")
            expect(page).to have_content("You need to pay a different fee")
          end

          within "#fee-change-response" do
            expect(page).to have_selector("h2", text: "Your response to this request")
            expect(page).to have_content("I am eligible for a fee reduction")
            expect(page).not_to have_selector("ul")
          end
        end

        it "can be responded to with documents" do
          visit "/fee_change_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
          expect(page).to have_selector("h1", text: "Provide evidence for fee concession or exemption")
          expect(page).to have_content("Send your response by 16 June 2025")

          within "#fee-change-reason" do
            expect(page).to have_selector("h3", text: "Comment from case officer")
            expect(page).to have_content("Incorrect fee")
          end

          within "#fee-change-suggestion" do
            expect(page).to have_selector("h3", text: "How to make your application valid")
            expect(page).to have_content("You need to pay a different fee")
          end

          click_button "Submit"
          expect(page).to have_selector("[role=alert] p", text: "There was a problem sending your response to the case officer")
          expect(page).to have_link("check the form below", href: "#validation-request-form")
          expect(page).to have_content("Tell us whether you agree or disagree with what was said")

          fill_in "Enter any comments", with: "I am eligible for a fee reduction"
          attach_file "Upload as many files as you need", "spec/fixtures/images/proposed-roofplan.png"

          click_button "Submit"
          expect(page).to have_selector("h1", text: "Your planning application")
          expect(page).to have_selector("[role=alert] p", text: "Your response has been sent to the case officer")

          within "#fee-change-validation-requests" do
            expect(page).to have_selector("h3", text: "Respond to fee change request")
            expect(page).to have_selector("strong.govuk-tag--green", text: "Complete")
            expect(page).to have_link("Check fee", href: %r{\A/fee_change_validation_requests/#{validation_request.id}})

            click_link "Check fee"
          end

          expect(page).to have_selector("h1", text: "Response to fee change request")

          within "#fee-change-reason" do
            expect(page).to have_selector("h2", text: "Officer’s reason for invalidating application:")
            expect(page).to have_content("Incorrect fee")
          end

          within "#fee-change-suggestion" do
            expect(page).to have_selector("h2", text: "How you can make your application valid:")
            expect(page).to have_content("You need to pay a different fee")
          end

          within "#fee-change-response" do
            expect(page).to have_selector("h2", text: "Your response to this request")
            expect(page).to have_content("I am eligible for a fee reduction")
            expect(page).to have_selector("ul")

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
      let(:validation_request_response) { nil }

      context "and the access control parameters are missing" do
        let(:access_control_params) { "" }

        it "returns an error page for the show action" do
          expect {
            visit "/fee_change_validation_requests/#{validation_request.id}?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end

        it "returns an error page for the edit action" do
          expect {
            visit "/fee_change_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end
      end

      context "and the access control parameters present" do
        it "shows the reason for the cancellation" do
          visit "/fee_change_validation_requests/#{validation_request.id}?#{access_control_params}"
          expect(page).to have_selector("h1", text: "Cancelled fee change request on your application")

          within "#cancellation-reason" do
            expect(page).to have_content("Made by mistake!")
            expect(page).to have_content("23 May 2025 13:00")
          end
        end

        it "returns an error page for the edit action" do
          expect {
            visit "/fee_change_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end
      end
    end

    context "and the request is closed" do
      let(:validation_request_status) { :closed }
      let(:validation_request_response) { "I am eligible for a fee reduction" }

      context "and the access control parameters are missing" do
        let(:access_control_params) { "" }

        it "returns an error page for the show action" do
          expect {
            visit "/fee_change_validation_requests/#{validation_request.id}?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end

        it "returns an error page for the edit action" do
          expect {
            visit "/fee_change_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end
      end

      context "and the access control parameters present" do
        context "and the response has no documents" do
          it "shows the response" do
            visit "/fee_change_validation_requests/#{validation_request.id}?#{access_control_params}"
            expect(page).to have_selector("h1", text: "Response to fee change request")

            within "#fee-change-reason" do
              expect(page).to have_selector("h2", text: "Officer’s reason for invalidating application:")
              expect(page).to have_content("Incorrect fee")
            end

            within "#fee-change-suggestion" do
              expect(page).to have_selector("h2", text: "How you can make your application valid:")
              expect(page).to have_content("You need to pay a different fee")
            end

            within "#fee-change-response" do
              expect(page).to have_selector("h2", text: "Your response to this request")
              expect(page).to have_content("I am eligible for a fee reduction")
              expect(page).not_to have_selector("ul")
            end
          end
        end

        context "and the response has documents" do
          let!(:document_1) { create(:document, :with_file, planning_application:) }
          let!(:document_2) { create(:document, :with_other_file, planning_application:) }
          let!(:preview_1) { document_1.representation(resize_to_fill: [360, 240, gravity: "North"]) }
          let!(:preview_2) { document_2.representation(resize_to_fill: [360, 240, gravity: "North"]) }

          before do
            validation_request.supporting_documents << document_1
            validation_request.supporting_documents << document_2
          end

          it "shows the response", skip: "flaky" do
            visit "/fee_change_validation_requests/#{validation_request.id}?#{access_control_params}"
            expect(page).to have_selector("h1", text: "Response to fee change request")

            within "#fee-change-reason" do
              expect(page).to have_selector("h2", text: "Officer’s reason for invalidating application:")
              expect(page).to have_content("Incorrect fee")
            end

            within "#fee-change-suggestion" do
              expect(page).to have_selector("h2", text: "How you can make your application valid:")
              expect(page).to have_content("You need to pay a different fee")
            end

            within "#fee-change-response" do
              expect(page).to have_selector("h2", text: "Your response to this request")
              expect(page).to have_content("I am eligible for a fee reduction")
              expect(page).to have_selector("ul")

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
        end

        it "returns an error page for the edit action" do
          expect {
            visit "/fee_change_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end
      end
    end
  end
end
