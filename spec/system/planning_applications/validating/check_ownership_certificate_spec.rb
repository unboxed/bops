# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Check ownership certificate type" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  before do
    sign_in assessor
    visit "/planning_applications/#{planning_application.reference}/validation/tasks"
  end

  context "when application is not started" do
    let!(:planning_application) { create(:planning_application, :not_started, local_authority: default_local_authority) }

    let!(:document1) { create(:document, planning_application:, tags: %w[floorPlan.proposed]) }
    let!(:document2) { create(:document, planning_application:, tags: %w[planningStatement]) }

    let!(:ownership_certificate) { create(:ownership_certificate, planning_application:) }
    let!(:land_owner1) { create(:land_owner, ownership_certificate:) }
    let!(:land_owner2) { create(:land_owner, :not_notified, ownership_certificate:) }

    context "when I agree with the type" do
      it "allows me to mark it as valid" do
        click_link "Check ownership certificate"

        find("span", text: "Documents").click

        expect(page).to have_content("Floor plan - proposed")
        expect(page).not_to have_content("Planning statement")

        expect(page).to have_content("Certificate type B")

        expect(page).to have_content(land_owner1.name)
        expect(page).to have_content(land_owner1.address_1)
        expect(page).to have_content(land_owner1.postcode)

        expect(page).to have_content(land_owner2.name)
        expect(page).to have_content(land_owner2.address_1)
        expect(page).to have_content(land_owner2.postcode)

        choose "Yes"

        click_button "Save and mark as complete"

        expect(page).to have_content "Ownership certificate successfully updated"

        within("#ownership-certificate-task") do
          expect(page).to have_content("Completed")
        end

        click_link "Check ownership certificate"

        expect(page).not_to have_content("Save and mark as complete")
      end
    end

    context "when I disagree with the type" do
      it "allows me to mark it as invalid" do
        click_link "Check ownership certificate"

        choose "No"

        click_button "Save and mark as complete"

        expect(page).to have_content "Request ownership certificate change"

        fill_in "Tell the applicant why their ownership certificate type is wrong", with: "It's a flat so you don't own the land"

        click_button "Save request"

        expect(page).to have_content "Ownership certificate request successfully created"

        click_link "Check ownership certificate"

        expect(page).to have_content "Request for more information about ownership certificate will be sent once application has been made invalid"
      end
    end
  end

  context "when planning application has been invalidated" do
    let!(:planning_application) { create(:planning_application, :invalidated, local_authority: default_local_authority) }
    let!(:request) { create(:ownership_certificate_validation_request, planning_application:, state: "open") }

    it "I can view it" do
      visit "/planning_applications/#{planning_application.reference}/validation/validation_requests"

      expect(page).to have_content("Ownership certificate")
      expect(page).to have_content(request.reason)

      click_link "View and update"

      expect(page).to have_content("View ownership certificate request")
      expect(page).to have_content(request.reason)
    end

    it "I can cancel my request" do
      visit "/planning_applications/#{planning_application.reference}/validation/validation_requests"

      expect(page).to have_content("Ownership certificate")
      expect(page).to have_content(request.reason)

      click_link "View and update"

      expect(page).to have_content("View ownership certificate request")
      expect(page).to have_content(request.reason)

      click_link "Cancel request"

      fill_in "Explain to the applicant why this request is being cancelled", with: "I made a mistake"

      click_button "Confirm cancellation"

      expect(page).to have_content("Ownership certificate request successfully cancelled")
    end

    context "when the applicant has responded with a rejection" do
      before do
        request.update(approved: false, rejection_reason: "I disagree", state: "closed")
      end

      it "I can view their response" do
        visit "/planning_applications/#{planning_application.reference}/validation/validation_requests"

        click_link "View and update"

        expect(page).to have_content "Check the response to ownership certificate request"
        expect(page).to have_content "Applicant response"
        expect(page).to have_content "Applicant rejected this ownership certificate change"
        expect(page).to have_content "Reason: I disagree"
      end
    end

    context "when the applicant has responded with approval" do
      before do
        request.update(approved: true, state: "closed")
        ownership_certificate = create(:ownership_certificate, planning_application:)
        create(:land_owner, ownership_certificate:)
      end

      it "I can view their response" do
        visit "/planning_applications/#{planning_application.reference}/validation/validation_requests"

        click_link "View and update"

        certificate = planning_application.ownership_certificate

        expect(page).to have_content "Check the response to ownership certificate request"
        expect(page).to have_content "Applicant response"
        expect(page).to have_content "The applicant provided this information:"
        expect(page).to have_content certificate.certificate_type
        expect(page).to have_content certificate.land_owners.first.name
      end
    end
  end

  context "when application type does not process ownership details" do
    let!(:planning_application) { create(:planning_application, local_authority: default_local_authority, application_type:) }
    let(:config) do
      create(:application_type_config, features:
        {
          "ownership_details" => false
        })
    end
    let(:application_type) { create(:application_type, config:, local_authority: default_local_authority) }

    it "does not provide a section for checking ownership details in assessment" do
      expect(page).not_to have_content("Check ownership certificate")
    end
  end
end
