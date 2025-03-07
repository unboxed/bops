# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Check ownership certificate" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  let(:config) do
    create(:application_type_config, features:
      {
        "ownership_details" => true
      })
  end

  let(:application_type) do
    create(:application_type, config:, local_authority: default_local_authority)
  end

  let(:planning_application) do
    create(
      :planning_application,
      :in_assessment,
      local_authority: default_local_authority,
      application_type:
    )
  end

  before do
    sign_in assessor
    visit "/planning_applications/#{planning_application.reference}/assessment/tasks"
  end

  context "when there is an ownership certificate" do
    let!(:ownership_certificate) { create(:ownership_certificate, planning_application:) }
    let!(:land_owner) { create(:land_owner, ownership_certificate:) }

    it "I can mark it as valid" do
      expect(list_item("Check ownership certificate")).to have_content("Not started")

      click_link "Check ownership certificate"

      expect(page).to have_content(ownership_certificate.certificate_type.upcase)
      expect(page).to have_content(land_owner.name)
      expect(page).to have_content(land_owner.address)

      click_button "Save and mark as complete"

      expect(page).to have_content("Ownership certificate was checked")

      expect(list_item("Check ownership certificate")).to have_content("Completed")

      click_link "Check ownership certificate"

      expect(page).to have_link("Edit ownership certificate", href: "/planning_applications/#{planning_application.reference}/assessment/ownership_certificate/edit")
    end

    it "I can request a new certificate" do
      click_link "Check ownership certificate"

      click_button "Request a new ownership certificate"

      fill_in "Tell the applicant why their ownership certificate type is wrong", with: "Not enough owners"

      click_button "Send request"

      expect(page).to have_content("Ownership certificate request successfully created")

      expect(list_item("Check ownership certificate")).to have_content("Invalid")

      click_link "Check ownership certificate"

      expect(page).to have_content "New ownership certificate requested"
      expect(page).to have_content "Applicant has not responded"

      # # Applicant responds
      ValidationRequest.last.update(state: "closed", approved: "true")

      visit "/planning_applications/#{planning_application.reference}/assessment/tasks"

      expect(list_item("Check ownership certificate")).to have_content("Not started")

      click_link "Check ownership certificate"
      expect(page).to have_content "Certificate submitted by applicant"

      click_button "Save and mark as complete"

      expect(list_item("Check ownership certificate")).to have_content("Completed")
    end
  end

  context "when there is not an ownership certificate" do
    it "I can request one" do
      expect(list_item("Check ownership certificate")).to have_content("Not started")

      click_link "Check ownership certificate"

      expect(page).to have_content "Not specified"

      click_button "Request a new ownership certificate"

      fill_in "Tell the applicant why their ownership certificate type is wrong", with: "Not enough owners"

      click_button "Send request"

      expect(page).to have_content("Ownership certificate request successfully created")

      expect(list_item("Check ownership certificate")).to have_content("Invalid")

      click_link "Check ownership certificate"

      expect(page).to have_content "New ownership certificate requested"
      expect(page).to have_content "Applicant has not responded"

      # # Applicant responds
      ValidationRequest.last.update(state: "closed", approved: "true")
      OwnershipCertificate.create(planning_application:, certificate_type: "a")

      visit "/planning_applications/#{planning_application.reference}/assessment/tasks"

      expect(list_item("Check ownership certificate")).to have_content("Not started")

      click_link "Check ownership certificate"
      expect(page).to have_content "Certificate type A"
      expect(page).to have_content "Certificate submitted by applicant"

      click_button "Save and mark as complete"

      expect(list_item("Check ownership certificate")).to have_content("Completed")
    end
  end

  context "when application type does not process ownership details" do
    let(:config) do
      create(:application_type_config, features:
        {
          "ownership_details" => false
        })
    end
    let(:application_type) do
      create(:application_type, config:, local_authority: default_local_authority)
    end

    it "does not provide a section for checking ownership details in assessment" do
      expect(page).not_to have_content("Check ownership certificate")
    end
  end
end
