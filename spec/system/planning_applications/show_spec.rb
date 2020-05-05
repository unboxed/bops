# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Planning Application show page", type: :system do
  let!(:assessor) { create(:user, :assessor) }
  let!(:site) { create(:site, address_1: "7 Elm Grove", town: "London", postcode: "SE15 6UT") }
  let!(:applicant) { create(:applicant, name: "James Applicant", phone: "07861637689", email: "james@example.com") }
  let!(:agent) { create(:agent, name: "Jennifer Agent", phone: "07861645689", email: "jennifer@example.com") }
  subject(:planning_application) { create(:planning_application, description: "Roof extension",
                                       application_type: "lawfulness_certificate",
                                       reference: "AP/453/880",
                                       status: 0,
                                       site: site,
                                       applicant: applicant,
                                       agent: agent) }

  context "as an assessor" do
    before do
      sign_in users(:assessor)
      visit "/planning_applications/#{planning_application.id}"
    end

    scenario "Site address is present" do
      expect(page).to have_text("7 Elm Grove")
    end

    scenario "Planning application code is correct" do
      expect(page).to have_text("AP/453/880")
    end

    scenario "Target date is correct and label is green" do
      expect(page).to have_text("Due: #{planning_application.target_date.strftime("%B %d")}")
      expect(page).to have_text("#{planning_application.days_left} days remaining")
      expect(page).to have_css('.govuk-tag--green')
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
      expect(page).to have_text(Time.zone.today.to_formatted_s(:long))
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

  context "as an assessor" do
    let(:target_date) { 1.week.from_now }
    let!(:planning_application) { create(:planning_application, :completed) }

    before do
      sign_in users(:assessor)
      visit "/planning_applications/#{planning_application.id}"
    end

    scenario "Target date is correct and label is red" do
      expect(page).to have_text("Due: #{planning_application.target_date.strftime("%B %d")}")
      expect(page).to have_text("#{planning_application.days_left} days remaining")
      expect(page).to have_css('.govuk-tag--red')
    end
  end
end
