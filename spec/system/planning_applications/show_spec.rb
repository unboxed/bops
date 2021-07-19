# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning Application show page", type: :system do
  let(:documents_validated_at) { Date.current - 2.weeks }
  let!(:api_user) { create :api_user }
  let!(:planning_application) do
    create :planning_application, description: "Roof extension",
                                  application_type: "lawfulness_certificate",
                                  status: :in_assessment,
                                  documents_validated_at: documents_validated_at,
                                  local_authority: @default_local_authority,
                                  payment_reference: "PAY123",
                                  payment_amount: 10_300,
                                  work_status: "proposed",
                                  uprn: "00773377",
                                  address_1: "7 Elm Grove",
                                  town: "London",
                                  postcode: "SE15 6UT",
                                  constraints: ["Conservation Area", "Listed Building"],
                                  api_user: api_user
  end
  let(:assessor) { create :user, :assessor, local_authority: @default_local_authority }

  context "as an assessor" do
    before do
      sign_in assessor
      visit planning_application_path(planning_application.id)
    end

    it "Site address is present" do
      expect(page).to have_text("7 Elm Grove, London, SE15 6UT")
    end

    it "Completed status is correct" do
      expect(page).to have_text("Work already started: No")
    end

    it "Planning application code is correct" do
      expect(page).to have_text(planning_application.reference)
    end

    it "Target date is correct and label is turquoise" do
      expect(page).to have_text("Target date: #{planning_application.target_date.strftime('%d %B')}")
      expect(page).to have_css(".govuk-tag--turquoise")
      expect(page).to have_content("In assessment")
    end

    it "Applicant information accordion" do
      click_button "Application information"

      expect(page).to have_text("Site address: 7 Elm Grove, London, SE15 6UT")
      expect(page).to have_text("UPRN: 00773377")
      expect(page).to have_link("View site on Google Maps")
      expect(page).to have_text("Application type: Lawful Development Certificate (Proposed)")
      expect(page).to have_text("Description: Roof extension")
      expect(page).to have_text("PAY123")
      expect(page).to have_text("£103.00")
    end

    it "Constraints accordion" do
      click_button "Constraints"

      expect(page).to have_text("Conservation Area")
    end

    it "Key application dates accordion" do
      click_button "Key application dates"

      expect(page).to have_text("Application received: #{Time.zone.now.strftime('%e %B %Y').strip}")
      expect(page).to have_text("Validation complete: #{Time.zone.now.strftime('%e %B %Y').strip}")
      expect(page).to have_text("Target date: #{planning_application.target_date.strftime('%e %B %Y').strip}")
      expect(page).to have_text("Expiry date: #{planning_application.expiry_date.strftime('%e %B %Y').strip}")
    end

    it "Result accordion" do
      click_button "Result from #{api_user.name}"

      expect(page).to have_text("Planning permission / Permission needed")
      expect(page).to have_text(planning_application.result_heading)
      expect(page).to have_text(planning_application.result_description)
      expect(page).to have_text("Override")
    end

    it "Contact information accordion" do
      click_button("Contact information")

      expect(page).to have_content(planning_application.agent_first_name)
      expect(page).to have_content(planning_application.agent_last_name)
      expect(page).to have_content(planning_application.agent_phone)
      expect(page).to have_content(planning_application.agent_email)

      expect(page).to have_content(planning_application.applicant_first_name)
      expect(page).to have_content(planning_application.applicant_last_name)
      expect(page).to have_content(planning_application.applicant_phone)
      expect(page).to have_content(planning_application.applicant_email)
    end

    it "Consultation accordion" do
      click_button("Consultation")

      expect(page).to have_text("Consultation is not applicable for proposed permitted development.")
    end

    it "Application information accordion is minimised by default" do
      within(".govuk-grid-column-two-thirds.application") do
        expect(page).to have_button("Open all")
      end
    end

    it "Supporting information accordion is minimised by default" do
      within(".govuk-grid-column-one-third.supporting") do
        expect(page).to have_button("Open all")
      end
    end

    it "Assessment tasks are visible" do
      expect(page).to have_text("Submit recommendation")
    end
  end

  context "as an assessor when target date is within a week" do
    let(:documents_validated_at) { Date.current - (7.weeks + 5.days) }

    before do
      sign_in assessor
      visit planning_application_path(planning_application.id)
    end

    it "Target date is correct" do
      expect(page).to have_text("Target date: #{planning_application.target_date.strftime('%d %B')}")
    end

    it "Breadcrumbs contain reference to Application overview which is not linked" do
      within(find(".govuk-breadcrumbs__list", match: :first)) do
        expect(page).to have_text "Application"
        expect(page).to have_no_link "Application"
      end
    end

    it "Breadcrumbs contain link to applications index" do
      expect(page).to have_text "Home"
      expect(page).to have_link "Home"
    end

    it "User can log out from application page" do
      click_button "Log out"

      expect(page).to have_current_path(/sign_in/)
      expect(page).to have_content("You need to sign in or sign up before continuing.")
    end
  end

  context "when work status is existing" do
    before do
      sign_in assessor
      planning_application.update!(work_status: "existing")
      visit planning_application_path(planning_application.reload.id)
    end

    it "displays the correct application type" do
      expect(page).to have_text("Application type: Lawful Development Certificate (Existing)")
    end
  end
end
