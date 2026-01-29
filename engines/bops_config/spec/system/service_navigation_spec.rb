# frozen_string_literal: true

require "bops_config_helper"

RSpec.describe "Service navigation", type: :system do
  let(:user) { create(:user, :global_administrator, name: "Clark Kent", local_authority: nil) }

  before do
    sign_in(user)
  end

  it "highlights Dashboard on the dashboard page" do
    visit "/dashboard"

    expect(page).to have_selector("a[aria-current]", text: "Dashboard")
  end

  it "highlights Users on the users page" do
    visit "/users"

    expect(page).to have_selector("a[aria-current]", text: "Users")
  end

  it "highlights Local authorities on the local authorities page" do
    create(:local_authority, :default)

    visit "/local_authorities"

    expect(page).to have_selector("a[aria-current]", text: "Local authorities")
  end

  context "when viewing local authority nested pages" do
    let!(:local_authority) { create(:local_authority, :default) }

    it "highlights Local authorities on the local authority users page" do
      visit "/local_authorities/#{local_authority.subdomain}/users"

      expect(page).to have_selector("a[aria-current]", text: "Local authorities")
    end
  end

  it "highlights Application types on the application types page" do
    visit "/application_types"

    expect(page).to have_selector("a[aria-current]", text: "Application types")
  end

  context "when viewing application type nested pages" do
    let!(:application_type) { create(:application_type_config, :ldc_proposed) }

    it "highlights Application types on the application type show page" do
      visit "/application_types/#{application_type.id}"

      expect(page).to have_selector("a[aria-current]", text: "Application types")
    end
  end

  it "highlights Legislation on the legislation page" do
    visit "/legislation"

    expect(page).to have_selector("a[aria-current]", text: "Legislation")
  end

  it "highlights Reporting types on the reporting types page" do
    visit "/reporting_types"

    expect(page).to have_selector("a[aria-current]", text: "Reporting types")
  end

  it "highlights Decisions on the decisions page" do
    visit "/decisions"

    expect(page).to have_selector("a[aria-current]", text: "Decisions")
  end

  context "when viewing GPDO pages" do
    let!(:schedule) { create(:policy_schedule, number: 2, name: "Permitted development rights") }

    it "highlights GPDO on the policy schedules page" do
      visit "/gpdo/schedule"

      expect(page).to have_selector("a[aria-current]", text: "GPDO")
    end

    it "highlights GPDO on the policy schedule edit page" do
      visit "/gpdo/schedule/#{schedule.number}/edit"

      expect(page).to have_selector("a[aria-current]", text: "GPDO")
    end
  end
end
