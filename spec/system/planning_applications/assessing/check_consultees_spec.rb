# frozen_string_literal: true

require "rails_helper"

RSpec.describe "checking consultees", js: true do
  let(:local_authority) { create(:local_authority, :default) }
  let(:assessor) { create(:user, :assessor, local_authority:) }
  let(:application_type) { create(:application_type, :planning_permission) }
  let(:api_user) { create(:api_user, name: "PlanX") }
  let(:planning_application) do
    create(
      :planning_application,
      :from_planx_prior_approval,
      :with_boundary_geojson,
      :with_constraints_and_consultees,
      application_type:,
      local_authority:,
      api_user:,
      agent_email: "agent@example.com",
      applicant_email: "applicant@example.com",
      make_public: true
    )
  end

  before do
    sign_in assessor
    visit "/planning_applications/#{planning_application.id}/assessment/tasks"
  end

  it "allows the assessor to see the list of constraints and consultees" do
    expect(page).to have_link("Check consultees consulted")
    expect(page).to have_selector("#check-consultees-consulted .govuk-tag", text: "Not started")

    click_link("Check consultees consulted")

    within ".govuk-table" do
      expect(page).to have_selector("tr:nth-child(1)", text: "Tree preservation zone")
      expect(page).to have_selector("tr:nth-child(1)", text: "Assign consultee")
      expect(page).to have_selector("tr:nth-child(1)", text: "Not assigned")
      expect(page).to have_selector("tr:nth-child(2)", text: "Listed building outline")
      expect(page).to have_selector("tr:nth-child(2)", text: "Harriet Historian")
      expect(page).to have_selector("tr:nth-child(2)", text: "Not consulted")
      expect(page).to have_selector("tr:nth-child(3)", text: "Conservation area")
      expect(page).to have_selector("tr:nth-child(3)", text: "Chris Wood")
      expect(page).to have_selector("tr:nth-child(3)", text: "Not consulted")
    end
  end

  it "allows assessor to mark as checked" do
    expect(page).to have_link("Check consultees consulted")
    expect(page).to have_selector("#check-consultees-consulted .govuk-tag", text: "Not started")
    click_link "Check consultees consulted"

    within ".govuk-table" do
      expect(page).to have_selector("tr:nth-child(3)", text: "Conservation area")
    end

    click_button "Confirm as checked"

    expect(page).to have_selector("#check-consultees-consulted .govuk-tag", text: "Completed")
  end

  it "allows assessor to add consultees from the summary page" do
    click_link "Check consultees consulted"

    within ".govuk-table" do
      expect(page).to have_selector("tr:nth-child(2)", text: "Listed building outline")
    end

    click_link "Add consultees"

    expect(page).to have_content("Select and add consultees")
  end
end
