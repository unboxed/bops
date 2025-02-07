# frozen_string_literal: true

require "bops_config_helper"

RSpec.describe "Local Authorities", type: :system, capybara: true do
  let(:user) { create(:user, :global_administrator, name: "Clark Kent", local_authority: nil) }
  let!(:local_authority) {
    create(:local_authority,
      :lambeth,
      :unconfigured,
      active: false,
      notify_api_key: "api_key",
      press_notice_email: "press@lambeth.gov.uk")
  }
  let!(:local_authority2) { create(:local_authority, :southwark, active: false) }
  let!(:local_authority3) {
    create(:local_authority,
      notify_api_key: "api_key",
      press_notice_email: "press@buckinghamshire.gov.uk",
      letter_template_id: "4896bb50-4f4c-4b4d-ad67-2caddddde125",
      reviewer_group_email: "ed.arnold@buckinghamshire.gov.uk")
  }

  before do
    sign_in(user)
    visit "/"
    click_link "Local authorities"
  end

  it "shows a list of all local authorities" do
    within("#all tbody tr:nth-child(1)") do
      expect(page).to have_content("BUC")
    end
  end

  it "breaks local authorities into two lists" do
    expect(page).to have_selector("h1", text: "Review all local authorities")
    expect(page).to have_selector("li.govuk-tabs__list-item--selected", text: "All")
    expect(page).to have_link("Active", href: "#active")
    expect(page).to have_link("Inactive", href: "#inactive")

    click_link("Active")
    expect(page).to have_selector("li.govuk-tabs__list-item--selected", text: "Active")

    within("#active table.govuk-table") do
      expect(page).to have_selector("tr:nth-child(1)", text: "Buckinghamshire")
      expect(page).to have_selector("tr:nth-child(1)", text: "Completed")
      expect(page).not_to have_content("LBH")
    end

    click_link("Inactive")
    expect(page).to have_selector("li.govuk-tabs__list-item--selected", text: "Inactive")

    within("#inactive table.govuk-table") do
      expect(page).to have_selector("tr:nth-child(1)", text: "Lambeth")
      expect(page).to have_selector("tr:nth-child(1)", text: "13 of 15")

      expect(page).to have_selector("tr:nth-child(2)", text: "Southwark")
      expect(page).to have_selector("tr:nth-child(2)", text: "11 of 15")

      expect(page).not_to have_content("Buckinghamshire")
    end
  end

  it "moves active local authorities to the correct tab" do
    click_link("Inactive")

    within("#inactive table.govuk-table") do
      expect(page).to have_selector("tr:nth-child(1)", text: "Lambeth")
    end

    local_authority.update!(reviewer_group_email: "sbarnes1@lambeth.gov.uk")
    local_authority.update!(letter_template_id: "5fe1d483-9bbe-4b56-8e71-8ce193fef723")
    visit current_path

    click_link("Active")
    within("#active table.govuk-table") do
      expect(page).to have_content("Lambeth")
    end
  end
end
