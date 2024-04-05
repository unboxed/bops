# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Consultation", js: true do
  let(:local_authority) { create(:local_authority, :default) }
  let(:assessor) { create(:user, :assessor, local_authority:) }
  let(:application_type) { create(:application_type, :planning_permission) }
  let(:api_user) { create(:api_user, name: "PlanX") }
  let(:planning_application) do
    create(
      :planning_application,
      :from_planx_prior_approval,
      :with_boundary_geojson,
      :with_constraints,
      application_type:,
      local_authority:,
      api_user:,
      agent_email: "agent@example.com",
      applicant_email: "applicant@example.com",
      make_public: true
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
    visit "/planning_applications/#{planning_application.id}/consultation"
  end

  it "lists constraints on the selection page" do
    click_link "Select and add consultees"

    within ".govuk-table" do
      expect(page).to have_selector("tr:nth-child(1)", text: "Conservation area")
      expect(page).to have_selector("tr:nth-child(1)", text: "Assign consultee")
      expect(page).to have_selector("tr:nth-child(2)", text: "Listed building outline")
      expect(page).to have_selector("tr:nth-child(2)", text: "Assign consultee")
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
      click_link "Assign consultee"
    end
    select "Chris Wood", from: "Consultee"
    click_button "Assign consultee"

    expect(page).to have_selector(".govuk-table__row", text: "Conservation area Chris Wood")
  end

  it "allows marking a constraint as requiring consultation" do
    click_link "Select and add consultees"

    fill_in "Search for consultees", with: "Tree Officer"
    pick "Chris Wood (Tree Officer, PlanX Council)", from: "#add-consultee"
    click_button "Add consultee"

    within "tbody tr:first-child" do
      click_link "Assign consultee"
    end

    check "Consultation required"
    click_button "Assign consultee"

    expect(page).not_to have_selector(".govuk-table__row", text: "Not required")
  end

  it "allows marking a constraint as not requiring consultation" do
    click_link "Select and add consultees"

    fill_in "Search for consultees", with: "Tree Officer"
    pick "Chris Wood (Tree Officer, PlanX Council)", from: "#add-consultee"
    click_button "Add consultee"

    within "tbody tr:first-child" do
      click_link "Assign consultee"
    end

    uncheck "Consultation required"
    click_button "Assign consultee"

    expect(page).to have_selector(".govuk-table__row", text: "Conservation area Assign consultee Not assigned Not required")
  end

  it "allows marking a constraint as not requiring consultation even with a consultee associated" do
    click_link "Select and add consultees"

    fill_in "Search for consultees", with: "Tree Officer"
    pick "Chris Wood (Tree Officer, PlanX Council)", from: "#add-consultee"
    click_button "Add consultee"

    within "tbody tr:first-child" do
      click_link "Assign consultee"
    end
    select "Chris Wood", from: "Consultee"
    uncheck "Consultation required"
    click_button "Assign consultee"

    expect(page).to have_selector(".govuk-table__row", text: "Conservation area Chris Wood Not consulted Not required")
  end
end
