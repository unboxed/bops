# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Profile", type: :system do
  let(:local_authority) { create(:local_authority, :default, :with_api_user) }
  let(:user) { create(:user, :administrator, local_authority:) }

  before do
    sign_in(user)
  end

  it "shows the council as active on the dashboard" do
    visit "/admin/dashboard"
    expect(page).to have_content("Active")
  end

  it "allows the administrator to view the determination period days" do
    visit "/admin/setting"
    expect(page).to have_selector("h1", text: "Application settings")
    expect(page).to have_selector("h2", text: "Determination period")

    within "dl div:nth-child(1)" do
      expect(page).to have_selector("dt", text: "Pre-application determination period")
      expect(page).to have_selector("dd", text: "30 days - bank holidays included")
      expect(page).to have_selector("dd > a", text: "Change")

      expect(page).to have_link(
        "Change",
        href: "/admin/setting/determination_period/edit"
      )
    end
  end

  it "allows the administrator to edit determination" do
    visit "/admin/setting"

    within "dl div:nth-child(1)" do
      expect(page).to have_selector("dt", text: "Pre-application determination period")
      expect(page).to have_selector("dd", text: "30 days - bank holidays included")
      click_link "Change"
    end

    # Set determination period
    expect(page).to have_selector(".govuk-label", text: "Set determination period")
    expect(page).to have_selector("div.govuk-hint", text: "Choose the length of the determination period for the pre-application type.")

    fill_in "Set determination period", with: ""
    click_button "Save"

    expect(page).to have_selector("[role=alert] li", text: "Determination period days can't be blank")

    fill_in "Set determination period", with: "not an integer"
    click_button "Save"

    expect(page).to have_selector("[role=alert] li", text: "Determination period days is not a number")

    fill_in "Set determination period", with: "1.1"
    click_button "Save"

    expect(page).to have_selector("[role=alert] li", text: "Determination period days must be an integer")

    fill_in "Set determination period", with: "0"
    click_button "Save"
    expect(page).to have_selector("[role=alert] li", text: "Determination period days must be greater than or equal to 1")

    fill_in "Set determination period", with: "100"
    click_button "Save"
    expect(page).to have_selector("[role=alert] li", text: "Determination period days must be less than or equal to 99")

    fill_in "Set determination period", with: "25"
    click_button "Save"

    expect(page).to have_content("Determination period successfully updated")
  end
end
