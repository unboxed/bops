# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning Application show page" do
  let(:validated_at) { 10.business_days.until(Date.current) }
  let(:default_local_authority) { create(:local_authority, :default) }
  let!(:api_user) { create(:api_user, name: "PlanX", local_authority: default_local_authority) }

  let(:proposal_details) do
    [
      {
        question: "What do you want to do?",
        responses: [{value: "Modify or extend"}],
        metadata: {section_name: "_root", auto_answered: true}
      },
      {
        question: "Is the property a house?",
        responses: [{value: "Yes"}],
        metadata: {section_name: "_root"}
      },
      {
        question: "What will the height of the new structure be?",
        responses: [{value: "2.5m"}],
        metadata: {section_name: "Dimensions", auto_answered: true}
      },
      {
        question: "Is the property in a world heritage site?",
        responses: [{value: "No"}]
      }
    ]
  end

  let(:config) { create(:application_type_config, :ldc_proposed) }
  let(:application_type) { create(:application_type, config:, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(
      :planning_application,
      description: "Roof extension",
      application_type:,
      status: :in_assessment,
      validated_at:,
      local_authority: default_local_authority,
      payment_reference: "PAY123",
      payment_amount: 103.00,
      uprn: "00773377",
      address_1: "7 Elm Grove",
      town: "London",
      postcode: "SE15 6UT",
      api_user:
    )
  end

  let(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  context "as an assessor" do
    before do
      sign_in assessor
      visit "/planning_applications/#{planning_application.reference}"
    end

    it "Site address is present" do
      expect(page).to have_text("7 Elm Grove, London, SE15 6UT")
    end

    it "Planning application code is correct" do
      expect(page).to have_text("#{planning_application.created_at.year % 100}-00100-LDCP")
    end

    it "Target date is correct and label is light blue" do
      expect(page).to have_text("Target date: #{planning_application.target_date.to_fs}")
      expect(page).to have_css(".govuk-tag--light-blue")
      expect(page).to have_content("In assessment")
    end

    it "Application type is visible" do
      expect(page).to have_content("Application type: Lawful Development Certificate - Proposed use")
    end

    it "Contact information accordion" do
      find("span", text: "Contact information").click

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

    context "when application type is planning permission" do
      let(:application_type) { create(:application_type, :planning_permission) }

      it "I can view the correct application type name and the planning application code" do
        expect(page).to have_content("#{planning_application.created_at.year % 100}-00100-HAPP")
      end
    end

    context "when application type has been changed" do
      before do
        planning_application.update!(application_type: create(:application_type, :ldc_existing))
        visit "/planning_applications/#{planning_application.reference}"
      end

      it "Displays previous application reference numbers" do
        expect(page).to have_text(
          "Application number: #{planning_application.created_at.year % 100}-00100-LDCE (Previously: #{planning_application.created_at.year % 100}-00100-LDCP)"
        )
      end
    end
  end

  context "as an assessor when target date is within a week" do
    let(:validated_at) { 40.business_days.until(Date.current) }

    before do
      sign_in assessor
      visit "/planning_applications/#{planning_application.reference}"
    end

    it "Breadcrumbs contain link to applications index" do
      expect(page).to have_text "Home"
      expect(page).to have_link "Home"
    end
  end
end
