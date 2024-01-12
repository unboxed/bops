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
      within(".govuk-hint") do
        expect(page).to have_content("This application is subject to an EIA. The determination period will be extended to 16 weeks.")
      end
    end

    it "I can mark the application as requiring an environment impact assessment" do
      click_link "Check Environment Impact Assessment"

      choose "Yes"
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
    end

    context "when application has been marked as requiring an environment impact assessment" do
      it "I can mark as it not being required if it's no longer necessary" do
        click_link "Check Environment Impact Assessment"
        choose "Yes"
        click_button "Save and mark as complete"
        expect(page).to have_content("Expiry date: 6 May 2024")

        click_link "Check Environment Impact Assessment"
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
