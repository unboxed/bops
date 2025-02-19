# frozen_string_literal: true

require "bops_config_helper"

RSpec.describe "Application Types", type: :system, capybara: true do
  let(:user) { create(:user, :global_administrator, name: "Clark Kent", local_authority: nil) }

  before do
    sign_in(user)
    visit "/"
  end

  it "allows adding a new application type" do
    create(:legislation, title: "Town and Country Planning Act 1990")

    create(:reporting_type, :major_dwellings)
    create(:reporting_type, :major_offices)
    create(:reporting_type, :major_industry)
    create(:reporting_type, :major_retail)

    create(:decision, :full_granted)
    create(:decision, :full_refused)

    visit "/application_types/new"
    expect(page).to have_selector("h1", text: "Application profile")

    click_button "Continue"
    expect(page).to have_selector("[role=alert] li", text: "Select an application type name")
    expect(page).to have_selector("[role=alert] li", text: "Enter a suffix for the application number")

    fill_in "Name", with: "Planning Permission - Major application"
    fill_in "Suffix", with: "MAJR"
    click_button "Continue"

    expect(page).to have_content("Application profile successfully created")

    # Choose category
    expect(page).to have_selector("h1", text: "Choose category")
    expect(page).to have_selector("h1 > span", text: "Planning Permission - Major application")
    expect(page).to have_selector("div.govuk-hint", text: "Choose the appropriate category for reporting codes")

    click_button "Continue"
    expect(page).to have_selector("[role=alert] li", text: "Choose a category from the list")

    choose "Full Planning Permission"
    click_button "Continue"

    expect(page).to have_content("Category successfully updated")

    # Select reporting types
    expect(page).to have_selector("h1", text: "Select reporting types")
    expect(page).to have_selector("h1 > span", text: "Planning Permission - Major application")
    expect(page).to have_selector("div.govuk-hint", text: "Select the possible reporting types for this application type on the planning matters return")

    click_button "Continue"
    expect(page).to have_selector("[role=alert] li", text: "A least one reporting type must be selected")

    check "Q01 – Dwellings (major)"
    check "Q02 – Offices, R&D, and light industry (major)"
    check "Q03 – General Industry, storage and warehousing (major)"
    check "Q04 – Retail and services (major)"
    click_button "Continue"

    expect(page).to have_content("Reporting successfully updated")

    # Enter legislation
    expect(page).to have_selector("h1", text: "Enter legislation")
    expect(page).to have_selector("h1 > span", text: "Planning Permission - Major application")
    expect(page).to have_selector("div.govuk-hint", text: "Enter either the name of an existing legislation that relates to this application type or create a new one.")
    expect(page).to have_selector("div.govuk-hint", text: "The title will appear in consultation letters, decision notices and other places that need to specify what the relevant legislation is.")

    choose "Choose an existing legislation"
    click_button "Continue"

    expect(page).to have_selector("[role=alert] li", text: "An existing legislation must be chosen")

    fill_in "Legislation title", with: "Town and Country Planning Act 1990"
    click_button "Continue"

    expect(page).to have_content("Legislation successfully updated")

    # Set determination period
    expect(page).to have_selector("h1", text: "Set determination period")
    expect(page).to have_selector("h1 > span", text: "Planning Permission - Major application")
    expect(page).to have_selector("div.govuk-hint", text: "Choose the length of the determination period for this type of application.")

    fill_in "Set determination period", with: ""
    click_button "Continue"

    expect(page).to have_selector("[role=alert] li", text: "Enter a number of days for the determination period")

    fill_in "Set determination period", with: "not an integer"
    click_button "Continue"

    expect(page).to have_selector("[role=alert] li", text: "The determination period must be a number of days")

    fill_in "Set determination period", with: "1.1"
    click_button "Continue"

    expect(page).to have_selector("[role=alert] li", text: "The determination period must be a whole number of days")

    fill_in "Set determination period", with: "0"
    click_button "Continue"
    expect(page).to have_selector("[role=alert] li", text: "The determination period must be at least 1 day")

    fill_in "Set determination period", with: "100"
    click_button "Continue"
    expect(page).to have_selector("[role=alert] li", text: "The determination period must be no more than 99 days")

    fill_in "Set determination period", with: "25"
    click_button "Continue"

    expect(page).to have_content("Determination period successfully updated")

    # Choose features
    expect(page).to have_selector("h1", text: "Choose features")
    expect(page).to have_selector("h1 > span", text: "Planning Permission - Major application")

    check "Check permitted development rights"
    check "Neighbours consultation"
    check "Assess policies and guidance (considerations)"
    click_button "Continue"

    expect(page).to have_content("Features successfully updated")

    # Manage document tags
    expect(page).to have_selector("h1", text: "Manage document tags")
    expect(page).to have_selector("h1 > span", text: "Planning Permission - Major application")
    expect(page).to have_selector("legend", text: "Drawings")
    expect(page).to have_selector("div.govuk-hint", text: "Select the relevant tags for drawings")

    check "Elevations - proposed"
    check "Elevations - existing"
    click_link "Evidence"

    expect(page).to have_selector("legend", text: "Evidence")
    expect(page).to have_selector("div.govuk-hint", text: "Select the relevant tags for evidence documents")

    check "Utility bill"
    check "Bank statement"
    click_link "Supporting documents"

    expect(page).to have_selector("legend", text: "Evidence")
    expect(page).to have_selector("div.govuk-hint", text: "Select the relevant tags for evidence documents")

    check "Sustainability statement"
    check "Environmental Impact Assessment (EIA)"
    click_button "Continue"

    expect(page).to have_content("Document tags successfully updated")

    # Set decisions
    expect(page).to have_selector("h1", text: "Choose decisions")
    click_button "Continue"

    expect(page).to have_content("You must choose at least one decision")

    check "Granted"
    check "Refused"
    click_button "Continue"
    expect(page).to have_content("Decisions successfully updated")

    # Review application type
    expect(page).to have_selector("h1", text: "Review the application type")
    expect(page).to have_selector("dl div:nth-child(1) dd", text: "Planning Permission - Major application")
    expect(page).to have_selector("dl div:nth-child(2) dd", text: "MAJR")
    expect(page).to have_selector("dl div:nth-child(3) dd", text: "Full Planning Permission")
    expect(page).to have_selector("dl div:nth-child(4) dd", text: "Q01, Q02, Q03, Q04")
    expect(page).to have_selector("dl div:nth-child(5) dd", text: "Town and Country Planning Act 1990")
    expect(page).to have_selector("dl div:nth-child(6) dd", text: "25 days - bank holidays included")
    expect(page).to have_selector("dl div:nth-child(7) dd li", text: "Check permitted development rights")
    expect(page).to have_selector("dl div:nth-child(7) dd li", text: "Neighbour")
    expect(page).to have_selector("dl div:nth-child(7) dd li", text: "Enable appeals")
    expect(page).to have_selector("dl div:nth-child(8) dd span:nth-child(1)", text: "Elevations - existing")
    expect(page).to have_selector("dl div:nth-child(8) dd span:nth-child(2)", text: "Elevations - proposed")
    expect(page).to have_selector("dl div:nth-child(9) dd span:nth-child(1)", text: "Bank statement")
    expect(page).to have_selector("dl div:nth-child(9) dd span:nth-child(2)", text: "Utility bill")
    expect(page).to have_selector("dl div:nth-child(10) dd span:nth-child(1)", text: "Environmental Impact Assessment (EIA)")
    expect(page).to have_selector("dl div:nth-child(10) dd span:nth-child(2)", text: "Sustainability statement")
    expect(page).to have_selector("dl div:nth-child(11) dd", text: "Granted, Refused")
    expect(page).to have_selector("dl div:nth-child(12) dd", text: "Inactive")
    expect(page).not_to have_selector("li", text: "Assess against policies and guidance")
    expect(page).to have_selector("li", text: "Assess policies and guidance (considerations)")
  end

  it "allows editing of an inactive application type" do
    application_type = create(:application_type, :configured, :ldc_proposed, status: "inactive")

    visit "/application_types/#{application_type.id}"
    expect(page).to have_selector("h1", text: "Review the application type")

    within "dl div:nth-child(1)" do
      click_link "Change"
    end

    expect(page).to have_selector("h1", text: "Application profile")

    fill_in "Name", with: "Lawful Development Certificate - Existing use"
    fill_in "Suffix", with: "LDCE"

    click_button "Continue"
    expect(page).to have_selector("h1", text: "Review the application type")
    expect(page).to have_selector("dl div:nth-child(1) dd", text: "Lawful Development Certificate - Existing use")
    expect(page).to have_selector("dl div:nth-child(2) dd", text: "LDCE")
  end

  it "prevents editing of an active application type" do
    application_type = create(:application_type, :ldc_proposed, status: "active")

    visit "/application_types/#{application_type.id}"
    expect(page).to have_selector("h1", text: "Review the application type")

    within "dl div:nth-child(1)" do
      expect(page).not_to have_link("Change")
    end

    within "dl div:nth-child(2)" do
      expect(page).not_to have_link("Change")
    end

    visit "/application_types/#{application_type.id}/edit"
    expect(page).to have_selector("h1", text: "Application profile")

    fill_in "Name", with: "Lawful Development Certificate - Existing use"
    fill_in "Suffix", with: "LDCE"

    click_button "Continue"
    expect(page).to have_selector("[role=alert] li", text: "The name can't be changed when the application type is active")
    expect(page).to have_selector("[role=alert] li", text: "The suffix can't be changed when the application type is active")
  end

  it "prevents editing of a retired application type" do
    application_type = create(:application_type, :ldc_proposed, status: "retired")

    visit "/application_types/#{application_type.id}"
    expect(page).to have_selector("h1", text: "Review the application type")

    within "dl div:nth-child(1)" do
      expect(page).not_to have_link("Change")
    end

    within "dl div:nth-child(2)" do
      expect(page).not_to have_link("Change")
    end

    visit "/application_types/#{application_type.id}/edit"
    expect(page).to have_selector("h1", text: "Application profile")

    fill_in "Name", with: "Lawful Development Certificate - Existing use"
    fill_in "Suffix", with: "LDCE"

    click_button "Continue"
    expect(page).to have_selector("[role=alert] li", text: "The name can't be changed when the application type is retired")
    expect(page).to have_selector("[role=alert] li", text: "The suffix can't be changed when the application type is retired")
  end

  it "allows activation of a new application type" do
    application_type = create(:application_type, :ldc_proposed, status: "inactive")

    visit "/application_types/#{application_type.id}"
    expect(page).to have_selector("h1", text: "Review the application type")

    within "dl div:nth-child(12)" do
      expect(page).to have_selector("dd", text: "Inactive")
      click_link "Change"
    end

    expect(page).to have_selector("h1", text: "Update status")
    expect(page).to have_selector("h1 > span", text: "Lawful Development Certificate - Proposed use")

    choose "Active"
    click_button "Continue"

    expect(page).to have_selector("h1", text: "Review the application type")
    expect(page).to have_selector("dl div:nth-child(12) dd", text: "Active")
  end

  it "prevents activation of a new application type when the category has not been set" do
    application_type = create(:application_type, :without_category, status: "inactive")

    visit "/application_types/#{application_type.id}"

    within "dl div:nth-child(12)" do
      expect(page).to have_selector("dd", text: "Inactive")
      click_link "Change"
    end

    choose "Active"
    click_button "Continue"

    expect(page).to have_selector("[role=alert] li", text: "A category must be set when an application type is made active")
    expect(page).to have_link(
      "A category must be set when an application type is made active",
      href: "/application_types/#{application_type.id}/category/edit"
    )

    click_link "A category must be set when an application type is made active"

    expect(page).to have_selector("h1", text: "Choose category")
    expect(page).to have_selector("h1 > span", text: "Lawful Development Certificate - Existing use")
  end

  it "prevents activation of a new application type when a reporting type has not been selected" do
    application_type = create(:application_type, :without_reporting_types, status: "inactive")

    visit "/application_types/#{application_type.id}"

    within "dl div:nth-child(12)" do
      expect(page).to have_selector("dd", text: "Inactive")
      click_link "Change"
    end

    choose "Active"
    click_button "Continue"

    expect(page).to have_selector("[role=alert] li", text: "A least one reporting type must be selected when an application type is made active")
    expect(page).to have_link(
      "A least one reporting type must be selected when an application type is made active",
      href: "/application_types/#{application_type.id}/reporting/edit"
    )

    click_link "A least one reporting type must be selected when an application type is made active"

    expect(page).to have_selector("h1", text: "Select reporting types")
    expect(page).to have_selector("h1 > span", text: "Lawful Development Certificate - Existing use")
  end

  it "prevents activation of a new application type when the legislation has not been set" do
    application_type = create(:application_type, :without_legislation, status: "inactive")

    visit "/application_types/#{application_type.id}"

    within "dl div:nth-child(12)" do
      expect(page).to have_selector("dd", text: "Inactive")
      click_link "Change"
    end

    choose "Active"
    click_button "Continue"

    expect(page).to have_selector("[role=alert] li", text: "The legislation must be set when an application type is made active")
    expect(page).to have_link(
      "The legislation must be set when an application type is made active",
      href: "/application_types/#{application_type.id}/legislation/edit"
    )

    click_link "The legislation must be set when an application type is made active"

    expect(page).to have_selector("h1", text: "Enter legislation")
    expect(page).to have_selector("h1 > span", text: "Lawful Development Certificate - Existing use")
  end

  it "allows retirement of an application type" do
    application_type = create(:application_type, :ldc_proposed, status: "active")

    visit "/application_types/#{application_type.id}"
    expect(page).to have_selector("h1", text: "Review the application type")

    within "dl div:nth-child(12)" do
      expect(page).to have_selector("dd", text: "Active")
      click_link "Change"
    end

    expect(page).to have_selector("h1", text: "Update status")
    expect(page).to have_selector("h1 > span", text: "Lawful Development Certificate - Proposed use")
    expect(page).to have_no_field("Inactive")

    choose "Retired"
    click_button "Continue"

    expect(page).to have_selector("h1", text: "Review the application type")
    expect(page).to have_selector("dl div:nth-child(12) dd", text: "Retired")
  end

  it "allows an application type to be brought out of retirement" do
    application_type = create(:application_type, :ldc_proposed, status: "retired")

    visit "/application_types/#{application_type.id}"

    expect(page).to have_selector("h1", text: "Review the application type")

    within "dl div:nth-child(12)" do
      expect(page).to have_selector("dd", text: "Retired")
      click_link "Change"
    end

    expect(page).to have_selector("h1", text: "Update status")
    expect(page).to have_selector("h1 > span", text: "Lawful Development Certificate - Proposed use")
    expect(page).to have_no_field("Inactive")

    choose "Active"
    click_button "Continue"

    expect(page).to have_selector("h1", text: "Review the application type")
    expect(page).to have_selector("dl div:nth-child(12) dd", text: "Active")
  end

  it "allows editing of the category" do
    application_type = create(:application_type, :configured, :ldc_proposed)

    visit "/application_types/#{application_type.id}"
    expect(page).to have_selector("h1", text: "Review the application type")

    within "dl div:nth-child(3)" do
      expect(page).to have_selector("dt", text: "Category")
      expect(page).to have_selector("dd:nth-child(2)", text: "Lawful Development Certificate")

      click_link "Change"
    end

    expect(page).to have_selector("h1", text: "Choose category")
    expect(page).to have_selector("h1 > span", text: "Lawful Development Certificate - Proposed use")

    choose "Change of Use"
    click_button "Continue"

    expect(page).to have_content("Category successfully updated")
    expect(page).to have_selector("h1", text: "Review the application type")

    within "dl div:nth-child(3)" do
      expect(page).to have_selector("dt", text: "Category")
      expect(page).to have_selector("dd:nth-child(2)", text: "Change of Use")
    end
  end

  it "allows editing of the reporting types" do
    create(:reporting_type, :prior_approval_1a)
    create(:reporting_type, :prior_approval_all_others)

    application_type = create(:application_type, :configured, :prior_approval)

    visit "/application_types/#{application_type.id}"
    expect(page).to have_selector("h1", text: "Review the application type")

    within "dl div:nth-child(4)" do
      expect(page).to have_selector("dt", text: "Reporting")
      expect(page).to have_selector("dd:nth-child(2)", text: "PA1")

      click_link "Change"
    end

    expect(page).to have_selector("h1", text: "Select reporting types")
    expect(page).to have_selector("h1 > span", text: "Prior Approval - Larger extension to a house")

    check "All others"
    click_button "Continue"

    expect(page).to have_content("Reporting successfully updated")
    expect(page).to have_selector("h1", text: "Review the application type")

    within "dl div:nth-child(4)" do
      expect(page).to have_selector("dt", text: "Reporting")
      expect(page).to have_selector("dd:nth-child(2)", text: "PA1, PA99")
    end
  end

  it "allows editing of the legislation" do
    legislation = create(:legislation, title: "Town and Country Planning Act 1990")
    determination_period_days = 25
    application_type = create(:application_type, :configured, :ldc_proposed, legislation:, determination_period_days:)

    visit "/application_types/#{application_type.id}"

    within "dl div:nth-child(5)" do
      click_link "Change"
    end

    expect(page).to have_selector("h1", text: "Enter legislation")
    expect(page).to have_selector("h1 > span", text: "Lawful Development Certificate - Proposed use")

    choose "Enter a new legislation"
    click_button "Continue"

    expect(page).to have_selector("[role=alert] li", text: "Enter a title for the legislation")

    fill_in "Title", with: "The Town and Country Planning (General Permitted Development) (England) Order 2015"
    fill_in "Link", with: "uksi/2015/596/contents"
    click_button "Continue"

    expect(page).to have_selector("[role=alert] li", text: "Enter a valid url for the legislation")

    fill_in "Link", with: "https://www.legislation.gov.uk/uksi/2015/596/contents"
    click_button "Continue"

    expect(page).to have_content("Legislation successfully updated")
    expect(page).to have_selector("h1", text: "Review the application type")
    expect(page).to have_selector("dl div:nth-child(5) dd", text: "The Town and Country Planning (General Permitted Development) (England) Order 2015")
  end

  it "allows editing of the determination period days" do
    application_type = create(:application_type, :configured, :ldc_proposed, determination_period_days: 25)

    visit "/application_types/#{application_type.id}"

    within "dl div:nth-child(6)" do
      click_link "Change"
    end

    expect(page).to have_selector("h1", text: "Set determination period")
    expect(page).to have_selector("h1 > span", text: "Lawful Development Certificate - Proposed use")

    fill_in "Set determination period", with: "35"
    click_button "Continue"

    expect(page).to have_content("Determination period successfully updated")
    expect(page).to have_selector("h1", text: "Review the application type")
    expect(page).to have_selector("dl div:nth-child(6) dd", text: "35 days - bank holidays included")
  end

  it "allows editing of the features" do
    application_type = create(
      :application_type, :configured, :ldc_proposed,
      features: {
        "informatives" => true,
        "planning_conditions" => true,
        "permitted_development_rights" => false,
        "consultation_steps" => ["neighbour", "publicity"],
        "appeals" => false
      }
    )

    visit "/application_types/#{application_type.id}"

    within "dl div:nth-child(7) dd.govuk-summary-list__value" do
      expect(page).to have_selector("p strong", text: "Application details")
      expect(page).to have_selector("li", text: "Add informatives")
      expect(page).to have_selector("li", text: "Ownership details")
      expect(page).to have_selector("li", text: "Check planning conditions")
      expect(page).to have_selector("li", text: "Environmental Impact Assessment")
      expect(page).to have_selector("li", text: "Community Infrastructure Levy")
      expect(page).to have_selector("li", text: "Check legislative requirments")
      expect(page).to have_selector("li", text: "Site visits")
      expect(page).not_to have_selector("li", text: "Check permitted development rights")
      expect(page).not_to have_selector("li", text: "Enable appeals")

      expect(page).to have_selector("p strong", text: "Consultation")
      expect(page).to have_selector("li", text: "Neighbour")
      expect(page).to have_selector("li", text: "Publicity")
      expect(page).not_to have_selector("li", text: "Consultee")
    end

    within "dl div:nth-child(7)" do
      click_link "Change"
    end

    expect(page).to have_selector("h1", text: "Choose features")
    expect(page).to have_selector("h1 > span", text: "Lawful Development Certificate - Proposed use")

    expect(page).to have_selector("fieldset legend", text: "Check application details")
    expect(page).to have_checked_field("Add informatives")
    expect(page).to have_checked_field("Ownership details")
    expect(page).to have_checked_field("Check planning conditions")
    expect(page).to have_checked_field("Site visits")
    expect(page).to have_unchecked_field("Check permitted development rights")

    expect(page).to have_selector("fieldset legend", text: "Consultation")
    expect(page).to have_checked_field("Neighbours consultation")
    expect(page).to have_checked_field("Publicity (site notice and press notice)")
    expect(page).to have_unchecked_field("Consultees")

    uncheck("Ownership details")
    uncheck("Check planning conditions")
    uncheck("Environmental Impact Assessment")
    uncheck("Community Infrastructure Levy")
    uncheck("Check legislative requirments")
    uncheck("Site visits")
    check("Check permitted development rights")
    check("Consultees")
    check("Enable appeals")

    click_button "Continue"

    expect(page).to have_content("Features successfully updated")
    expect(page).to have_selector("h1", text: "Review the application type")

    within "dl div:nth-child(7) dd.govuk-summary-list__value" do
      expect(page).to have_selector("p strong", text: "Application details")
      expect(page).to have_selector("li", text: "Add informatives")
      expect(page).not_to have_selector("li", text: "Ownership details")
      expect(page).not_to have_selector("li", text: "Check planning conditions")
      expect(page).not_to have_selector("li", text: "Environmental Impact Assessment")
      expect(page).not_to have_selector("li", text: "Community Infrastructure Levy")
      expect(page).not_to have_selector("li", text: "Check legislative requirments")
      expect(page).not_to have_selector("li", text: "Site visits")
      expect(page).to have_selector("li", text: "Check permitted development rights")
      expect(page).to have_selector("li", text: "Enable appeals")

      expect(page).to have_selector("p strong", text: "Consultation")
      expect(page).to have_selector("li", text: "Neighbour")
      expect(page).to have_selector("li", text: "Publicity")
      expect(page).to have_selector("li", text: "Consultee")
    end

    application_type.reload
    expect(application_type.informatives?).to eq(true)
    expect(application_type.ownership_details?).to eq(false)
    expect(application_type.planning_conditions?).to eq(false)
    expect(application_type.eia?).to eq(false)
    expect(application_type.cil?).to eq(false)
    expect(application_type.legislative_requirements?).to eq(false)
    expect(application_type.permitted_development_rights?).to eq(true)
    expect(application_type.consultation_steps).to eq(["neighbour", "consultee", "publicity"])
    expect(application_type.appeals?).to eq(true)
  end

  it "allows editing of the tags for drawings" do
    application_type = create(
      :application_type, :configured, :ldc_proposed,
      document_tags: {
        "drawings" => %w[elevations.existing]
      }
    )

    visit "/application_types/#{application_type.id}"

    within "dl div:nth-child(8) dd:nth-child(2)" do
      expect(page).to have_selector("span", text: "Elevations - existing")
      expect(page).not_to have_selector("span", text: "Elevations - proposed")
    end

    within "dl div:nth-child(8) dd:nth-child(3)" do
      click_link "Change"
    end

    expect(page).to have_selector("h1", text: "Manage document tags")
    expect(page).to have_selector("h1 > span", text: "Lawful Development Certificate - Proposed use")
    expect(page).to have_selector("legend", text: "Drawings")
    expect(page).to have_selector("div.govuk-hint", text: "Select the relevant tags for drawings")

    uncheck "Elevations - existing"
    check "Elevations - proposed"
    click_button "Continue"

    expect(page).to have_content("Document tags successfully updated")
    expect(page).to have_selector("h1", text: "Review the application type")
    expect(page).to have_selector("dl div:nth-child(8) dd span", text: "Elevations - proposed")
    expect(page).not_to have_selector("dl div:nth-child(8) dd span", text: "Elevations - existing")
  end

  it "allows editing of the tags for evidence" do
    application_type = create(
      :application_type, :configured, :ldc_proposed,
      document_tags: {
        "evidence" => %w[bankStatement]
      }
    )

    visit "/application_types/#{application_type.id}"

    within "dl div:nth-child(9) dd:nth-child(2)" do
      expect(page).to have_selector("span", text: "Bank statement")
      expect(page).not_to have_selector("span", text: "Utility bill")
    end

    within "dl div:nth-child(9) dd:nth-child(3)" do
      click_link "Change"
    end

    expect(page).to have_selector("h1", text: "Manage document tags")
    expect(page).to have_selector("h1 > span", text: "Lawful Development Certificate - Proposed use")
    expect(page).to have_selector("legend", text: "Evidence")
    expect(page).to have_selector("div.govuk-hint", text: "Select the relevant tags for evidence documents")

    uncheck "Bank statement"
    check "Utility bill"
    click_button "Continue"

    expect(page).to have_content("Document tags successfully updated")
    expect(page).to have_selector("h1", text: "Review the application type")
    expect(page).to have_selector("dl div:nth-child(9) dd span", text: "Utility bill")
    expect(page).not_to have_selector("dl div:nth-child(9) dd span", text: "Bank statement")
  end

  it "allows editing of the tags for supporting documents" do
    application_type = create(
      :application_type, :configured, :ldc_proposed,
      document_tags: {
        "supporting_documents" => %w[environmentalImpactAssessment]
      }
    )

    visit "/application_types/#{application_type.id}"

    within "dl div:nth-child(10) dd:nth-child(2)" do
      expect(page).to have_selector("span", text: "Environmental Impact Assessment (EIA)")
      expect(page).not_to have_selector("span", text: "Sustainability statement")
    end

    within "dl div:nth-child(10) dd:nth-child(3)" do
      click_link "Change"
    end

    expect(page).to have_selector("h1", text: "Manage document tags")
    expect(page).to have_selector("h1 > span", text: "Lawful Development Certificate - Proposed use")
    expect(page).to have_selector("legend", text: "Supporting documents")
    expect(page).to have_selector("div.govuk-hint", text: "Select the relevant tags for supporting documents")

    uncheck "Environmental Impact Assessment (EIA)"
    check "Sustainability statement"
    click_button "Continue"

    expect(page).to have_content("Document tags successfully updated")
    expect(page).to have_selector("h1", text: "Review the application type")
    expect(page).to have_selector("dl div:nth-child(10) dd span", text: "Sustainability statement")
    expect(page).not_to have_selector("dl div:nth-child(10) dd span", text: "Environmental Impact Assessment (EIA)")
  end

  it "allows editing of the decisions for recommendation" do
    create(:decision, :pa_granted)
    create(:decision, :pa_not_required)
    create(:decision, :pa_refused)

    application_type = create(:application_type, :configured, :prior_approval)

    visit "/application_types/#{application_type.id}"
    expect(page).to have_selector("h1", text: "Review the application type")

    within "dl div:nth-child(11)" do
      expect(page).to have_selector("dt", text: "Decisions")
      expect(page).to have_selector("dd:nth-child(2)", text: "Granted, Not required, Refused")

      click_link "Change"
    end

    expect(page).to have_selector("h1", text: "Choose decisions")

    uncheck "Prior approval not required"
    click_button "Continue"

    expect(page).to have_content("Decisions successfully updated")
    expect(page).to have_selector("h1", text: "Review the application type")

    within "dl div:nth-child(11)" do
      expect(page).to have_selector("dt", text: "Decisions")
      expect(page).to have_selector("dd:nth-child(2)", text: "Granted, Refused")
    end
  end

  it "displays application types" do
    ldc_existing = create(:application_type, :ldc_existing, status: "active")
    ldc_proposed = create(:application_type, :ldc_proposed, status: "retired")
    prior_approval = create(:application_type, :prior_approval, status: "active")
    planning_permission = create(:application_type, :planning_permission, status: "inactive")

    visit "/application_types"
    expect(page).to have_selector("h1", text: "Application Types")

    expect(page).to have_link(
      "Create new application type",
      href: "/application_types/new"
    )

    within("#active table") do
      within "thead > tr:first-child" do
        expect(page).to have_selector("th:nth-child(1)", text: "Suffix")
        expect(page).to have_selector("th:nth-child(2)", text: "Name")
        expect(page).to have_selector("th:nth-child(3)", text: "Status")
        expect(page).to have_selector("th:nth-child(4)", text: "Action")
      end

      within "tbody" do
        within "tr:nth-child(1)" do
          expect(page).to have_selector("td:nth-child(1)", text: "PA")
          expect(page).to have_selector("td:nth-child(2)", text: "Prior Approval - Larger extension to a house")
          expect(page).to have_selector("td:nth-child(3) .govuk-tag--green", text: "Active")

          within "td:nth-child(4)" do
            expect(page).to have_link(
              "View and/or edit",
              href: "/application_types/#{prior_approval.id}"
            )
          end
        end

        within "tr:nth-child(2)" do
          expect(page).to have_selector("td:nth-child(1)", text: "LDCE")
          expect(page).to have_selector("td:nth-child(2)", text: "Lawful Development Certificate - Existing use")
          expect(page).to have_selector("td:nth-child(3) .govuk-tag--green", text: "Active")

          within "td:nth-child(4)" do
            expect(page).to have_link(
              "View and/or edit",
              href: "/application_types/#{ldc_existing.id}"
            )
          end
        end
      end
    end

    within("#inactive table") do
      within "thead > tr:first-child" do
        expect(page).to have_selector("th:nth-child(1)", text: "Suffix")
        expect(page).to have_selector("th:nth-child(2)", text: "Name")
        expect(page).to have_selector("th:nth-child(3)", text: "Status")
        expect(page).to have_selector("th:nth-child(4)", text: "Action")
      end

      within "tbody" do
        within "tr:nth-child(1)" do
          expect(page).to have_selector("td:nth-child(1)", text: "HAPP")
          expect(page).to have_selector("td:nth-child(2)", text: "Planning Permission - Full householder")
          expect(page).to have_selector("td:nth-child(3) .govuk-tag--grey", text: "Inactive")

          within "td:nth-child(4)" do
            expect(page).to have_link(
              "View and/or edit",
              href: "/application_types/#{planning_permission.id}"
            )
          end
        end
      end
    end

    within("#retired table") do
      within "thead > tr:first-child" do
        expect(page).to have_selector("th:nth-child(1)", text: "Suffix")
        expect(page).to have_selector("th:nth-child(2)", text: "Name")
        expect(page).to have_selector("th:nth-child(3)", text: "Status")
        expect(page).to have_selector("th:nth-child(4)", text: "Action")
      end

      within "tbody" do
        within "tr:nth-child(1)" do
          expect(page).to have_selector("td:nth-child(1)", text: "LDCP")
          expect(page).to have_selector("td:nth-child(2)", text: "Lawful Development Certificate - Proposed use")
          expect(page).to have_selector("td:nth-child(3) .govuk-tag--red", text: "Retired")

          within "td:nth-child(4)" do
            expect(page).to have_link(
              "View and/or edit",
              href: "/application_types/#{ldc_proposed.id}"
            )
          end
        end
      end
    end
  end
end
