# frozen_string_literal: true

require "bops_applicants_helper"

RSpec.describe "Ownership certificate validation requests" do
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
        visit "/ownership_certificate_validation_requests/123"
      }.to raise_error(BopsCore::Errors::NotFoundError)
    end
  end

  context "when a validation request exists" do
    let!(:validation_request) do
      create(
        :ownership_certificate_validation_request,
        validation_request_status,
        planning_application:,
        reason: "The certificate is missing some land owners",
        approved: validation_request_approved,
        rejection_reason: validation_request_rejection_reason
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
            visit "/ownership_certificate_validation_requests/#{validation_request.id}?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end

        it "returns an error page for the edit action" do
          expect {
            visit "/ownership_certificate_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end
      end

      context "and the access control parameters present" do
        let(:ownership_certificate) { planning_application.ownership_certificate }
        let(:land_owner) { ownership_certificate.land_owners.first }

        it "returns an error page for the show action" do
          expect {
            visit "/ownership_certificate_validation_requests/#{validation_request.id}?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end

        it "can be agreed with" do
          visit "/ownership_certificate_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
          expect(page).to have_selector("h1", text: "Confirm ownership")

          within "#ownership-certificate-reason" do
            expect(page).to have_content("The certificate is missing some land owners")
          end

          click_button "Submit"
          expect(page).to have_selector("[role=alert] p", text: "There was a problem sending your response to the case officer")
          expect(page).to have_link("check the form below", href: "#validation-request-form")
          expect(page).to have_content("Tell us whether you agree or disagree with the statement")

          choose "Yes, I agree"

          click_button "Submit"
          expect(page).to have_selector("h1", text: "Confirm ownership")

          click_button "Continue"

          within_fieldset "Do you know how many owners there are?" do
            expect(page).to have_content("Tell us whether you know how many owners there are")
            choose "No or not sure"
          end

          within_fieldset "Do you know who the owners of the property are?" do
            expect(page).to have_content("Tell us if you know who the owners are")
            choose "I know who some of them are"
          end

          within_fieldset "Have you notified the owners of the land about this application?" do
            expect(page).to have_content("Tell us whether you have notified the owners")
            choose "No"
          end

          click_button "Continue"
          expect(page).to have_content("You must notify other owners about the proposed work")

          within "#land-owners" do
            expect(page).to have_selector("h2", text: "Add details of other owners")
            expect(page).to have_content("You’ve not told us about any owners yet")

            click_button "Add owner"
          end

          expect(page).to have_selector("h3", text: "Details of owner")

          click_button "Add owner"
          expect(page).to have_content("Enter the owner’s name")
          expect(page).to have_content("Enter the owner’s address")
          expect(page).to have_content("Enter the owner’s town or city")
          expect(page).to have_content("Enter the owner’s postcode")

          fill_in "Owner name", with: "Alice Smith"
          fill_in "Address line 1", with: "1 Main Street"
          fill_in "Address line 2", with: "Barnacle"
          fill_in "Town or city", with: "Coventry"
          fill_in "Postcode", with: "CV7 1AA"

          within_fieldset "What date was notice given to this owner?" do
            fill_in "Day", with: "1"
            fill_in "Month", with: "4"
            fill_in "Year", with: "2025"
          end

          click_button "Add owner"

          within "#land-owners tbody tr" do
            within "td:nth-of-type(1)" do
              expect(page).to have_content <<~TEXT.squish
                Alice Smith
                1 Main Street
                Barnacle
                Coventry
                CV7 1AA
              TEXT
            end

            within "td:nth-of-type(2)" do
              expect(page).to have_content("Yes")
            end

            within "td:nth-of-type(3)" do
              expect(page).to have_content("01/04/2025")
            end
          end

          expect {
            click_button "Accept and send"
            expect(page).to have_content("Your ownership certificate has been sent to the case officer")
          }.to change {
            planning_application.reload.ownership_certificate
          }.from(nil).to(an_instance_of(OwnershipCertificate))

          expect(ownership_certificate).to be_present
          expect(ownership_certificate).to have_attributes(certificate_type: "c")

          expect(land_owner).to be_present
          expect(land_owner).to have_attributes(
            name: "Alice Smith",
            address_1: "1 Main Street",
            address_2: "Barnacle",
            town: "Coventry",
            postcode: "CV7 1AA",
            notice_given: true,
            notice_given_at: "2025-04-01".in_time_zone
          )

          within "#ownership-certificate-validation-requests" do
            expect(page).to have_selector("h3", text: "Confirm ownership of the land")
            expect(page).to have_selector("strong.govuk-tag--green", text: "Complete")
            expect(page).to have_link("Confirm ownership", href: %r{\A/ownership_certificate_validation_requests/#{validation_request.id}})

            click_link "Confirm ownership"
          end

          expect(page).to have_selector("h1", text: "Response to ownership certificate change request")

          within "#ownership-certificate-reason" do
            expect(page).to have_selector("h2", text: "Officer's reason for invalidating application")
            expect(page).to have_content("The certificate is missing some land owners")
          end

          within "#ownership-certificate-response" do
            expect(page).to have_content("Agreed with suggested ownership certificate change")
            expect(page).not_to have_link("Submit new ownership certificate")
          end
        end

        it "can be disagreed with" do
          visit "/ownership_certificate_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
          expect(page).to have_selector("h1", text: "Confirm ownership")

          within "#ownership-certificate-reason" do
            expect(page).to have_content("The certificate is missing some land owners")
          end

          choose "No, I don’t agree"

          click_button "Submit"
          expect(page).to have_selector("[role=alert] p", text: "There was a problem sending your response to the case officer")
          expect(page).to have_link("check the form below", href: "#validation-request-form")
          expect(page).to have_content("Tell us why you disagree with the statement")

          fill_in "Tell us why you don’t agree", with: "I am the sole owner of this property"

          click_button "Submit"
          expect(page).to have_selector("h1", text: "Your planning application")
          expect(page).to have_selector("[role=alert] p", text: "Your response has been sent to the case officer")

          within "#ownership-certificate-validation-requests" do
            expect(page).to have_selector("h3", text: "Confirm ownership of the land")
            expect(page).to have_selector("strong.govuk-tag--green", text: "Complete")
            expect(page).to have_link("Confirm ownership", href: %r{\A/ownership_certificate_validation_requests/#{validation_request.id}})

            click_link "Confirm ownership"
          end

          expect(page).to have_selector("h1", text: "Response to ownership certificate change request")

          within "#ownership-certificate-reason" do
            expect(page).to have_selector("h2", text: "Officer's reason for invalidating application")
            expect(page).to have_content("The certificate is missing some land owners")
          end

          within "#ownership-certificate-response" do
            expect(page).to have_content("Disagreed with suggested ownership certificate change")
            expect(page).to have_content("I am the sole owner of this property")
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
            visit "/ownership_certificate_validation_requests/#{validation_request.id}?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end

        it "returns an error page for the edit action" do
          expect {
            visit "/ownership_certificate_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end
      end

      context "and the access control parameters present" do
        it "shows the reason for the cancellation" do
          visit "/ownership_certificate_validation_requests/#{validation_request.id}?#{access_control_params}"
          expect(page).to have_selector("h1", text: "Cancelled request for confirmation of ownership")

          within "#cancellation-reason" do
            expect(page).to have_content("Made by mistake!")
            expect(page).to have_content("23 May 2025 13:00")
          end
        end

        it "returns an error page for the edit action" do
          expect {
            visit "/ownership_certificate_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
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
            visit "/ownership_certificate_validation_requests/#{validation_request.id}?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end

        it "returns an error page for the edit action" do
          expect {
            visit "/ownership_certificate_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end
      end

      context "and the access control parameters present" do
        context "and the request was approved" do
          let(:validation_request_approved) { true }
          let(:validation_request_rejection_reason) { nil }

          it "shows the response" do
            visit "/ownership_certificate_validation_requests/#{validation_request.id}?#{access_control_params}"
            expect(page).to have_selector("h1", text: "Response to ownership certificate change request")

            within "#ownership-certificate-reason" do
              expect(page).to have_selector("h2", text: "Officer's reason for invalidating application")
              expect(page).to have_content("The certificate is missing some land owners")
            end

            within "#ownership-certificate-response" do
              expect(page).to have_content("Agreed with suggested ownership certificate change")
            end
          end
        end

        context "and the request was rejected" do
          let(:validation_request_approved) { false }
          let(:validation_request_rejection_reason) { "There are no other land owners" }

          it "shows the response" do
            visit "/ownership_certificate_validation_requests/#{validation_request.id}?#{access_control_params}"
            expect(page).to have_selector("h1", text: "Response to ownership certificate change request")

            within "#ownership-certificate-reason" do
              expect(page).to have_selector("h2", text: "Officer's reason for invalidating application")
              expect(page).to have_content("The certificate is missing some land owners")
            end

            within "#ownership-certificate-response" do
              expect(page).to have_content("Disagreed with suggested ownership certificate change")
              expect(page).to have_content("There are no other land owners")
            end
          end
        end

        it "returns an error page for the edit action" do
          expect {
            visit "/ownership_certificate_validation_requests/#{validation_request.id}/edit?#{access_control_params}"
          }.to raise_error(BopsCore::Errors::NotFoundError)
        end
      end
    end
  end
end
