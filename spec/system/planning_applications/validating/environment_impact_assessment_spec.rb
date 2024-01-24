# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Validation tasks" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  let!(:planning_application) do
    travel_to(DateTime.new(2024, 1, 15)) { create(:planning_application, :invalidated, local_authority: default_local_authority) }
  end

  before do
    sign_in assessor
    visit "/planning_applications/#{planning_application.id}/validation/tasks"
  end

  context "when application is not started or invalidated" do
    it "displays the content when checking for the environment impact assessment" do
      expect(page).to have_content("Expiry date: 11 March 2024")
      click_link "Check Environment Impact Assessment"

      expect(page).to have_content("Environment Impact Assessment (EIA)")
      expect(page).to have_content(planning_application.full_address)
      expect(page).to have_content(planning_application.reference)
      expect(page).to have_content(planning_application.description)

      expect(page).to have_content("Does the application require an assessment?")
      expect(page).to have_link(
        "Check EIA guidance", href: "https://www.gov.uk/government/publications/environmental-impact-assessment-screening-checklist"
      )
      expect(page).to have_content("This application is subject to an EIA. The determination period will be extended to 16 weeks.")
    end

    it "I can mark the application as requiring an environment impact assessment" do
      click_link "Check Environment Impact Assessment"

      choose "Yes"
      fill_in "Enter an address where members of the public can view or request a copy of the Environmental Statement. Include name/number, street, town, postcode (optional).", with: "123 street"
      fill_in "Enter the fee to obtain a hard copy of the Environmental Statement (optional).", with: "196"
      fill_in "Enter an email address where members of the public can request a copy of the Environmental Statement (optional).", with: "email@example.com"
      click_button "Save and mark as complete"

      within(".govuk-notification-banner--notice") do
        expect(page).to have_content("Application marked as requiring an EIA. The determination period is extended to 16 weeks.")
      end
      within("#dates-and-assignment-details") do
        expect(page).to have_content("Expiry date: 6 May 2024")
        expect(page).to have_content("Subject to an EIA")
        expect(page).to have_content("The expiry date has been extended to 16 weeks")
      end
      within("#environment-impact-assessment-task") do
        within(".govuk-tag") do
          expect(page).to have_content("Required")
        end
      end

      visit "/planning_applications/#{planning_application.id}/audits"
      within("#audit_#{Audit.last.id}") do
        expect(page).to have_content("Changed to: true")
        expect(page).to have_content("Environment impact assessment updated")
        expect(page).to have_content(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
      end

      expect(planning_application.reload.environment_impact_assessment.address).to eq "123 street"
      expect(planning_application.reload.environment_impact_assessment.email_address).to eq "email@example.com"
      expect(planning_application.reload.environment_impact_assessment.fee).to eq 196
    end

    it "I can edit the information" do
      click_link "Check Environment Impact Assessment"

      choose "Yes"
      fill_in "Enter an address where members of the public can view or request a copy of the Environmental Statement. Include name/number, street, town, postcode (optional).", with: "123 street"
      fill_in "Enter the fee to obtain a hard copy of the Environmental Statement (optional).", with: "196"
      fill_in "Enter an email address where members of the public can request a copy of the Environmental Statement (optional).", with: "email@example.com"
      click_button "Save and mark as complete"

      within(".govuk-notification-banner--notice") do
        expect(page).to have_content("Application marked as requiring an EIA. The determination period is extended to 16 weeks.")
      end
      within("#dates-and-assignment-details") do
        expect(page).to have_content("Expiry date: 6 May 2024")
        expect(page).to have_content("Subject to an EIA")
        expect(page).to have_content("The expiry date has been extended to 16 weeks")
      end
      within("#environment-impact-assessment-task") do
        within(".govuk-tag") do
          expect(page).to have_content("Required")
        end
      end

      click_link "Check Environment Impact Assessment"
      click_link "Edit information"

      fill_in "Enter an address where members of the public can view or request a copy of the Environmental Statement. Include name/number, street, town, postcode (optional).", with: "456 street"
      fill_in "Enter the fee to obtain a hard copy of the Environmental Statement (optional).", with: "195"
      fill_in "Enter an email address where members of the public can request a copy of the Environmental Statement (optional).", with: "edited_email@example.com"

      click_button "Save and mark as complete"

      within(".govuk-notification-banner--notice") do
        expect(page).to have_content("Application marked as requiring an EIA. The determination period is extended to 16 weeks.")
      end

      expect(planning_application.reload.environment_impact_assessment.address).to eq "456 street"
      expect(planning_application.reload.environment_impact_assessment.email_address).to eq "edited_email@example.com"
      expect(planning_application.reload.environment_impact_assessment.fee).to eq 195
    end

    it "shows errors" do
      click_link "Check Environment Impact Assessment"

      choose "Yes"

      fill_in "Enter an address where members of the public can view or request a copy of the Environmental Statement. Include name/number, street, town, postcode (optional).", with: "456 street"
      fill_in "Enter an email address where members of the public can request a copy of the Environmental Statement (optional).", with: "invalid_email.com"

      click_button "Save and mark as complete"

      within(".govuk-error-summary") do
        expect(page).to have_content "Fee can't be blank if the address has been entered. Enter a fee or enter '0' if there is no fee."
        expect(page).to have_content "Email address is invalid"
      end

      within(".govuk-form-group--error #environment-impact-assessment-fee-error") do
        expect(page).to have_content "Fee can't be blank if the address has been entered. Enter a fee or enter '0' if there is no fee."
      end

      fill_in "Enter an address where members of the public can view or request a copy of the Environmental Statement. Include name/number, street, town, postcode (optional).", with: ""
      fill_in "Enter the fee to obtain a hard copy of the Environmental Statement (optional).", with: "195"
      fill_in "Enter an email address where members of the public can request a copy of the Environmental Statement (optional).", with: "email@example.com"

      click_button "Save and mark as complete"

      within(".govuk-error-summary") do
        expect(page).to have_content "You have entered a fee but not provided an address. Enter an address where the fee can be paid."
      end

      within(".govuk-form-group--error") do
        expect(page).to have_content "You have entered a fee but not provided an address. Enter an address where the fee can be paid."
      end

      fill_in "Enter the fee to obtain a hard copy of the Environmental Statement (optional).", with: ""

      click_button "Save and mark as complete"

      within(".govuk-notification-banner--notice") do
        expect(page).to have_content("Application marked as requiring an EIA. The determination period is extended to 16 weeks.")
      end
    end

    context "when application has been marked as requiring an environment impact assessment" do
      it "I can mark as it not being required if it's no longer necessary" do
        click_link "Check Environment Impact Assessment"
        choose "Yes"
        click_button "Save and mark as complete"
        expect(page).to have_content("Expiry date: 6 May 2024")

        click_link "Check Environment Impact Assessment"
        click_link "Edit information"
        choose "No"
        click_button "Save and mark as complete"

        within("#environment-impact-assessment-task") do
          within(".govuk-tag") do
            expect(page).to have_content("Not required")
          end
        end

        expect(page).to have_content("Expiry date: 11 March 2024")
        expect(page).not_to have_content("Subject to an EIA")

        visit "/planning_applications/#{planning_application.id}/audits"
        within("#audit_#{Audit.last.id}") do
          expect(page).to have_content("Changed from: true Changed to: false")
          expect(page).to have_content("Environment impact assessment updated")
          expect(page).to have_content(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
        end
      end
    end
  end
end
