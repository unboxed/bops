# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning Application show page", type: :system do
  let(:local_authority) { create :local_authority }
  let!(:site) { create :site, address_1: "7 Elm Grove", town: "London", postcode: "SE15 6UT" }
  let!(:planning_application) do
    create :planning_application, description: "Roof extension",
                                  application_type: "lawfulness_certificate", status: :in_assessment,
                                  ward: "Dulwich Wood", site: site,
                                  target_date: Date.current + 14.days, local_authority: local_authority,
                                  payment_reference: "PAY123",
                                  work_status: "proposed",
                                  constraints: '{"conservation_area": true, "article4_area": false, "scheduled_monument": false }'
  end
  let(:assessor) { create :user, :assessor, local_authority: local_authority }
  let(:reviewer) { create :user, :reviewer, local_authority: local_authority }

  context "as an assessor" do
    before do
      sign_in assessor
      visit planning_application_path(planning_application.id)
    end

    it "Site address is present" do
      expect(page).to have_text("7 Elm Grove, London, SE15 6UT")
    end

    it "Completed status is correct" do
      expect(page).to have_text("Work already completed: No")
    end

    it "Planning application code is correct" do
      expect(page).to have_text("Fast track application: #{planning_application.reference}")
    end

    it "Target date is correct and label is green" do
      expect(page).to have_text("Due: #{planning_application.target_date.strftime('%d %B')}")
      expect(page).to have_text("#{planning_application.days_left} days remaining")
      expect(page).to have_css(".govuk-tag--green")
    end

    it "Applicant information accordion" do
      click_button "Application information"

      expect(page).to have_text("Address: 7 Elm Grove, London, SE15 6UT")
      expect(page).to have_text("Ward: Dulwich Wood")
      expect(page).to have_text("Building type: Residential")
      expect(page).to have_text("Application type: Proposed permitted development: Certificate of Lawfulness")
      expect(page).to have_text("Summary: Roof extension")
      expect(page).to have_text("PAY123")
    end

    it "Constraints accordion" do
      click_button "Constraints"

      expect(page).to have_text("Conservation Area")
    end

    it "Key application dates accordion" do
      click_button "Key application dates"

      expect(page).to have_text("Application status: In assessment")
      expect(page).to have_text("Application received: #{Time.zone.now.strftime('%e %B %Y').strip}")
      expect(page).to have_text("Validation complete: #{Time.zone.now.strftime('%e %B %Y').strip}")
      expect(page).to have_text("Target date: #{planning_application.target_date.strftime('%e %B %Y').strip}")
      expect(page).to have_text("Statutory date: #{planning_application.target_date.strftime('%e %B %Y').strip}")
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
      expect(page).to have_text("Make recommendation")
    end

    it "Review tasks are not visible" do
      expect(page).not_to have_text("Determine the proposal")
    end
  end

  context "as an assessor when target date is within a week" do
    let(:target_date) { 1.week.from_now }
    let!(:planning_application) { create :planning_application, :determined, local_authority: local_authority }

    before do
      sign_in assessor
      visit planning_application_path(planning_application.id)
    end

    it "Target date is correct and label is red" do
      expect(page).to have_text("Due: #{planning_application.target_date.strftime('%d %B')}")
      expect(page).to have_text("#{planning_application.days_left} days remaining")
      expect(page).to have_css(".govuk-tag--red")
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
end
