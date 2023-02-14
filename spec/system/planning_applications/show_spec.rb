# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning Application show page" do
  let(:validated_at) { 10.business_days.until(Date.current) }
  let!(:api_user) { create(:api_user) }
  let!(:default_local_authority) { create(:local_authority, :default) }

  let(:proposal_details) do
    [
      {
        question: "What do you want to do?",
        responses: [{ value: "Modify or extend" }],
        metadata: { portal_name: "_root", auto_answered: true }
      },
      {
        question: "Is the property a house?",
        responses: [{ value: "Yes" }],
        metadata: { portal_name: "_root" }
      },
      {
        question: "What will the height of the new structure be?",
        responses: [{ value: "2.5m" }],
        metadata: { portal_name: "Dimensions", auto_answered: true }
      },
      {
        question: "Is the property in a world heritage site?",
        responses: [{ value: "No" }]
      }
    ].to_json
  end

  let!(:planning_application) do
    create(
      :planning_application,
      description: "Roof extension",
      application_type: "lawfulness_certificate",
      status: :in_assessment,
      validated_at: validated_at,
      local_authority: default_local_authority,
      payment_reference: "PAY123",
      payment_amount: 103.00,
      work_status: "proposed",
      uprn: "00773377",
      address_1: "7 Elm Grove",
      town: "London",
      postcode: "SE15 6UT",
      constraints: ["Conservation Area", "Listed Building"],
      api_user: api_user
    )
  end

  let(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  context "as an assessor" do
    before do
      sign_in assessor
      visit planning_application_path(planning_application)
    end

    it "Site address is present" do
      expect(page).to have_text("7 Elm Grove, London, SE15 6UT")
    end

    it "Planning application code is correct" do
      expect(page).to have_text("#{planning_application.created_at.year % 100}-00100-LDCP")
    end

    it "Target date is correct and label is turquoise" do
      expect(page).to have_text("Target date: #{planning_application.target_date.to_fs}")
      expect(page).to have_css(".govuk-tag--turquoise")
      expect(page).to have_content("In assessment")
    end

    it "Contact information accordion" do
      click_button("Contact information")

      expect(page).to have_content("Applicant role type:")
      expect(page).to have_content(planning_application.user_role)

      expect(page).to have_content(planning_application.agent_first_name)
      expect(page).to have_content(planning_application.agent_last_name)
      expect(page).to have_content(planning_application.agent_phone)
      expect(page).to have_content(planning_application.agent_email)

      expect(page).to have_content(planning_application.applicant_first_name)
      expect(page).to have_content(planning_application.applicant_last_name)
      expect(page).to have_content(planning_application.applicant_phone)
      expect(page).to have_content(planning_application.applicant_email)
    end

    it "Assessment tasks are visible" do
      expect(page).to have_text("Check and assess")
    end
  end

  context "as an assessor when target date is within a week" do
    let(:validated_at) { 40.business_days.until(Date.current) }

    before do
      sign_in assessor
      visit planning_application_path(planning_application)
    end

    it "Breadcrumbs contain reference to Application overview which is not linked" do
      within(find(".govuk-breadcrumbs__list", match: :first)) do
        expect(page).to have_text "Application"
        expect(page).not_to have_link "Application"
      end
    end

    it "Breadcrumbs contain link to applications index" do
      expect(page).to have_text "Home"
      expect(page).to have_link "Home"
    end
  end
end
