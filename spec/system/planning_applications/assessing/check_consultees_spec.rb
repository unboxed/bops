# frozen_string_literal: true

require "rails_helper"

RSpec.describe "checking consultees", js: true do
  let(:local_authority) { create(:local_authority, :default) }
  let(:assessor) { create(:user, :assessor, local_authority:) }
  let(:application_type) { create(:application_type, :planning_permission) }
  let(:api_user) { create(:api_user, :planx) }
  let(:planning_application) do
    create(
      :planning_application,
      :from_planx_prior_approval,
      :with_boundary_geojson,
      :with_constraints_and_consultees,
      :published,
      application_type:,
      local_authority:,
      api_user:,
      agent_email: "agent@example.com",
      applicant_email: "applicant@example.com"
    )
  end

  before do
    sign_in assessor
    visit "/planning_applications/#{planning_application.reference}/assessment/tasks"
  end

  it "allows the assessor to see the list of constraints and consultees" do
    expect(page).to have_link("Check consultees consulted")
    expect(page).to have_selector("#check-consultees-consulted .govuk-tag", text: "Not started")

    click_link("Check consultees consulted")

    within ".govuk-table" do
      within "tr:nth-child(1)" do
        expect(page).to have_content("Tree preservation zone")
        expect(page).to have_link("Assign consultees")
        expect(page).to have_selector(".govuk-tag", text: "Not assigned")
      end

      within "tr:nth-child(2)" do
        expect(page).to have_content("Listed building outline")
        expect(page).to have_selector("li", text: "Harriet Historian")
        expect(page).to have_selector(".govuk-tag", text: "Not consulted")
      end

      within "tr:nth-child(3)" do
        expect(page).to have_content("Conservation area")
        expect(page).to have_selector("li", text: "Chris Wood")
        expect(page).to have_selector(".govuk-tag", text: "Not consulted")
      end
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
