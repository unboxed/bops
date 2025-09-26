# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Consultation", type: :system, js: true do
  let(:local_authority) { create(:local_authority, :default) }
  let(:assessor) { create(:user, :assessor, local_authority:) }
  let(:application_type) { create(:application_type, :planning_permission) }
  let(:api_user) { create(:api_user, :planx) }
  let(:planning_application) do
    create(
      :planning_application,
      :from_planx_prior_approval,
      :with_boundary_geojson,
      :with_constraints,
      :published,
      application_type:,
      local_authority:,
      api_user:,
      agent_email: "agent@example.com",
      applicant_email: "applicant@example.com"
    )
  end

  before do
    create(
      :contact, :external,
      name: "Consultations",
      role: "Planning Department",
      organisation: "GLA",
      email_address: "planning@london.gov.uk"
    )

    create(
      :contact, :internal,
      local_authority:,
      name: "Chris Wood",
      role: "Tree Officer",
      organisation: local_authority.council_name,
      email_address: "chris.wood@#{local_authority.subdomain}.gov.uk"
    )
    sign_in assessor
    visit "/planning_applications/#{planning_application.reference}/consultation"
  end

  it "lists constraints on the selection page" do
    click_link "Select and add consultees"

    within ".govuk-table" do
      expect(page).to have_selector("tr:nth-child(1)", text: "Conservation area")
      expect(page).to have_selector("tr:nth-child(1)", text: "Assign consultees")
      expect(page).to have_selector("tr:nth-child(2)", text: "Listed building outline")
      expect(page).to have_selector("tr:nth-child(2)", text: "Assign consultees")
    end
  end

  it "allows adding a consultee" do
    click_link "Select and add consultees"
    fill_in "Search for consultees", with: "Tree Officer"
    expect(page).to have_selector("#add-consultee__listbox li:first-child", text: "Chris Wood (Tree Officer, PlanX Council)")

    pick "Chris Wood (Tree Officer, PlanX Council)", from: "#add-consultee"
    expect(page).to have_field("Search for consultees", with: "Chris Wood")

    click_button "Add consultee"

    expect(page).to have_selector(".govuk-table__row", text: "Other Chris Wood")
  end

  it "allows associating a consultee with a constraint" do
    click_link "Select and add consultees"

    fill_in "Search for consultees", with: "Tree Officer"
    pick "Chris Wood (Tree Officer, PlanX Council)", from: "#add-consultee"
    click_button "Add consultee"

    within "tbody tr:first-child" do
      click_link "Assign consultees"
    end
    check "Chris Wood"
    click_button "Assign consultees"

    row = find("tbody tr", text: "Chris Wood")
    expect(row).to have_text("Chris Wood")
    expect(row).to have_selector(".govuk-tag", text: "Not consulted")
  end

  it "allows assigning multiple consultees and removing one" do
    click_link "Select and add consultees"

    fill_in "Search for consultees", with: "Tree Officer"
    pick "Chris Wood (Tree Officer, PlanX Council)", from: "#add-consultee"
    click_button "Add consultee"

    fill_in "Search for consultees", with: "Consultations"
    pick "Consultations (Planning Department, GLA)", from: "#add-consultee"
    click_button "Add consultee"

    within "tbody tr:first-child" do
      click_link "Assign consultees"
    end

    check "Chris Wood"
    check "Consultations"
    click_button "Assign consultees"

    expect(page).to have_selector("tbody tr", text: "Chris Wood")
    expect(page).to have_selector("tbody tr", text: "Consultations")

    click_link "Manage consultees"

    uncheck "Consultations"
    click_button "Assign consultees"

    expect(page).to have_selector("tbody tr", text: "Chris Wood")
    expect(page).not_to have_selector("tbody tr", text: "Consultations")
  end

  it "allows marking a constraint as requiring consultation" do
    click_link "Select and add consultees"

    fill_in "Search for consultees", with: "Tree Officer"
    pick "Chris Wood (Tree Officer, PlanX Council)", from: "#add-consultee"
    click_button "Add consultee"

    within "tbody tr:first-child" do
      click_link "Assign consultees"
    end

    check "Consultation required?"
    click_button "Assign consultees"

    expect(page).not_to have_selector(".govuk-table__row", text: "Not required")
  end

  it "allows marking a constraint as not requiring consultation" do
    click_link "Select and add consultees"

    fill_in "Search for consultees", with: "Tree Officer"
    pick "Chris Wood (Tree Officer, PlanX Council)", from: "#add-consultee"
    click_button "Add consultee"

    within "tbody tr:first-child" do
      click_link "Assign consultees"
    end

    uncheck "Consultation required?"
    click_button "Assign consultees"

    within "tbody tr", text: "Assign consultees" do
      expect(page).to have_link("Assign consultees")
      expect(page).to have_selector(".govuk-tag", text: "Not assigned")
      expect(page).to have_selector(".govuk-tag", text: "Not required")
    end
  end

  it "allows marking a constraint as not requiring consultation even with a consultee associated" do
    click_link "Select and add consultees"

    fill_in "Search for consultees", with: "Tree Officer"
    pick "Chris Wood (Tree Officer, PlanX Council)", from: "#add-consultee"
    click_button "Add consultee"

    within "tbody tr:first-child" do
      click_link "Assign consultees"
    end
    check "Chris Wood"
    uncheck "Consultation required?"
    click_button "Assign consultees"

    row = find("tbody tr", text: "Chris Wood")
    expect(row).to have_selector(".govuk-tag", text: "Not consulted")
    expect(row).to have_selector(".govuk-tag", text: "Not required")
  end

  context "when no consultees are required" do
    before do
      planning_application.consultation.consultees.clear
      planning_application.planning_application_constraints.clear
    end

    it "allows marking as not requiring consultees" do
      visit "/planning_applications/#{planning_application.reference}/consultation"

      within "#consultee-tasks" do
        within "li:nth-child(1)" do
          expect(page).to have_selector("a", text: "Select and add consultees")
          expect(page).to have_selector("strong", text: "Not started")
        end

        within "li:nth-child(2)" do
          expect(page).to have_selector("a", text: "Send emails to consultees")
          expect(page).to have_selector("strong", text: "Not started")
        end

        within "li:nth-child(3)" do
          expect(page).to have_selector("a", text: "View consultee responses")
          expect(page).to have_selector("strong", text: "Not started")
        end
      end

      click_link "Select and add consultees"
      expect(page).to have_content("No reasons or constraints have been identified, so there are no suggested consultees.")

      click_button "Mark consultees as not required"
      expect(page).to have_content("Consultation was successfully updated")

      within "#consultee-tasks" do
        within "li:nth-child(1)" do
          expect(page).to have_selector("a", text: "Select and add consultees")
          expect(page).to have_selector("strong", text: "Complete")
        end

        within "li:nth-child(2)" do
          expect(page).to have_selector("a", text: "Send emails to consultees")
          expect(page).to have_selector("strong", text: "Complete")
        end

        within "li:nth-child(3)" do
          expect(page).to have_selector("a", text: "View consultee responses")
          expect(page).to have_selector("strong", text: "Complete")
        end
      end
    end
  end
end
