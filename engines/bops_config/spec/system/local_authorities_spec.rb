# frozen_string_literal: true

require "bops_config_helper"

RSpec.describe "Local Authorities", type: :system, capybara: true do
  before do
    local_authority = create(:local_authority, :southwark)
    create(:api_user, :validation_requests_ro, name: "bops-applicants", local_authority:, token: "bops_letmeinpleasethisisabsolutelysecurereally_")
  end

  let(:user) { create(:user, :global_administrator, name: "Clark Kent", local_authority: nil) }
  let!(:local_authority) {
    create(:local_authority,
      :lambeth,
      :unconfigured,
      active: false,
      notify_api_key: "api_key",
      press_notice_email: "press@lambeth.gov.uk")
  }
  let!(:local_authority2) { create(:local_authority, :southwark, :unconfigured, active: false) }
  let!(:local_authority3) {
    create(:local_authority,
      notify_api_key: "api_key",
      press_notice_email: "press@buckinghamshire.gov.uk",
      email_template_id: "b16231c6-88c9-44f1-99cd-43eb3de57ef5",
      sms_template_id: "62589764-f668-45a7-b5b1-61b96d08dbb8",
      letter_template_id: "4896bb50-4f4c-4b4d-ad67-2caddddde125",
      reviewer_group_email: "ed.arnold@buckinghamshire.gov.uk")
  }

  before do
    sign_in(user)

    visit "/"
    expect(page).to have_selector("h1", text: "BOPS config")

    click_link "Local authorities"
    expect(page).to have_selector("h1", text: "Review all local authorities")
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
      expect(page).to have_selector("tr:nth-child(1)", text: "12 of 17")

      expect(page).to have_selector("tr:nth-child(2)", text: "Southwark")
      expect(page).to have_selector("tr:nth-child(2)", text: "10 of 17")

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

  it "visits the local authorities show page" do
    click_link("Active")
    within("#active table.govuk-table") do
      click_link(local_authority3.short_name)
    end

    expect(page).to have_content("Buckinghamshire")
    expect(page).to have_content("press@buckinghamshire.gov.uk")
    expect(page).not_to have_content("Not started")
    expect(page).not_to have_content("digitalplanning@lambeth.gov.uk")
  end

  it "allows local authorities to be onboarded" do
    env = ActiveSupport::StringInquirer.new("production")
    allow(Bops).to receive(:env).and_return(env)

    api = instance_double("Apis::PlanningData::Query")
    allow(Apis::PlanningData::Query).to receive(:new).and_return(api)
    allow(api).to receive(:get_council_code).with("COV").and_return("COV")

    click_link "Onboard local authority"
    expect(page).to have_selector("h1", text: "Onboard a local authority")

    fill_in "Short name", with: "Coventry"
    fill_in "Council name", with: "Coventry City Council"
    fill_in "Council code", with: "COV"
    fill_in "Subdomain", with: "coventry"
    fill_in "Applicants URL", with: "https://planningapplications.coventry.gov.uk"

    fill_in "Full name", with: "Lady Godiva"
    fill_in "Email address", with: "lady.godiva@example.com"

    click_button "Save"
    expect(page).to have_content("Local authority successfully created")

    local_authority = LocalAuthority.find_by!(council_code: "COV")
    administrator = local_authority.users.first!
    api_user = ApiUser.find_by!(local_authority:, name: "bops-applicants")

    expect(local_authority).to have_attributes(
      short_name: "Coventry",
      council_name: "Coventry City Council",
      council_code: "COV",
      subdomain: "coventry",
      applicants_url: "https://planningapplications.coventry.gov.uk"
    )

    expect(administrator).to have_attributes(
      name: "Lady Godiva",
      email: "lady.godiva@example.com",
      role: "administrator"
    )

    expect(api_user).not_to be_nil
  end
end
