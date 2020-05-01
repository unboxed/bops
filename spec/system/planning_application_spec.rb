# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Home page renders correctly", type: :system do
  let!(:assessor) { create(:user, :assessor) }
  let!(:site) { create(:site, address_1: "7 Elm Grove", town: "London", postcode: "SE15 6UT") }
  let!(:applicant) { create(:applicant, name: "James Applicant", phone: "07861637689", email: "james@example.com") }
  let!(:agent) { create(:agent, name: "Jennifer Agent", phone: "07861645689", email: "jennifer@example.com") }
  subject(:planning_application) { create(:planning_application, description: "Roof extension",
                                       submission_date: "2020-04-28",
                                       application_type: "lawfulness_certificate",
                                       reference: "AP/453/880",
                                       status: 0,
                                       site: site,
                                       applicant: applicant,
                                       agent: agent) }

  context "as an assessor" do
    before do
      sign_in(assessor)
      visit "/planning_applications/#{planning_application.id}"
    end

    scenario "Site address is present" do
      expect(page).to have_text("7 Elm Grove")
    end

    scenario "Planning application code is correct" do
      expect(page).to have_text("AP/453/880")
    end

    scenario "Status is correct" do
      within(".govuk-grid-column-two-thirds.application") do
         first('.govuk-accordion').click_button('Open all')
         expect(page).to have_text("Ready For Assessment")
       end
    end

    scenario "Submission date is correct" do
      within(".govuk-grid-column-two-thirds.application") do
        first('.govuk-accordion').click_button('Open all')
        expect(page).to have_text("April 28, 2020")
      end
    end

    scenario "Applicant name is correct" do
      within(".govuk-grid-column-one-third.supporting") do
        click_button("Open all")
      end
      expect(page).to have_text(planning_application.applicant.name)
    end

    scenario "Applicant phone is correct" do
      within(".govuk-grid-column-one-third.supporting") do
        click_button("Open all")
      end
      expect(page).to have_text(planning_application.applicant.phone)
    end

    scenario "Applicant email is correct" do
      within(".govuk-grid-column-one-third.supporting") do
        click_button('Open all')
      end
      expect(page).to have_text(planning_application.applicant.email)
    end

    scenario "Agent name is correct" do
      within(".govuk-grid-column-one-third.supporting") do
        click_button('Open all')
      end
      expect(page).to have_text(planning_application.agent.name)
    end

    scenario "Agent phone is correct" do
      within(".govuk-grid-column-one-third.supporting") do
        click_button('Open all')
      end
      expect(page).to have_text(planning_application.agent.phone)
    end

    scenario "Agent email is correct" do
      within(".govuk-grid-column-one-third.supporting") do
        click_button('Open all')
      end
      expect(page).to have_text(planning_application.agent.email)
    end

    scenario "Application information accordion is minimised by default" do
      within(".govuk-grid-column-two-thirds.application") do
        expect(page).to have_button("Open all")
      end
    end

    scenario "Supporting information accordion is minimised by default" do
      within(".govuk-grid-column-one-third.supporting") do
        expect(page).to have_button("Open all")
      end
    end

    scenario "Assessment tasks are visible" do
      expect(page).to have_text("Assess the proposal")
    end

    scenario "Review tasks are visible" do
      expect(page).to have_text("Determine the proposal")
    end

    scenario "Constraints section is visible" do
      within(".govuk-grid-column-one-third.supporting") do
        click_button('Open all')
      end
      expect(page).to have_text("Constraints")
    end

    scenario "Property history section is visible" do
      within(".govuk-grid-column-one-third.supporting") do
        click_button('Open all')
      end
      expect(page).to have_text("Property history")
    end

    scenario "Consultation section is visible" do
      within(".govuk-grid-column-one-third.supporting") do
        click_button('Open all')
      end
      expect(page).to have_text("Consultation")
    end

    scenario "Site address is visible in Supporting information accordion" do
      within(".govuk-grid-column-one-third.supporting") do
        click_button('Open all')
      end
      expect(page).to have_text(planning_application.site.address_1)
    end
  end
end
