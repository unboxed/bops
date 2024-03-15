# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Application Types", type: :system, bops_config: true do
  let(:user) { create(:user, :global_administrator, name: "Clark Kent", local_authority: nil) }

  before do
    sign_in(user)
    visit "/"
  end

  it "allows adding a new application type" do
    visit "/application_types/new"
    expect(page).to have_selector("h1", text: "Application profile")

    click_button "Continue"
    expect(page).to have_selector("[role=alert] li", text: "Select an application type name")
    expect(page).to have_selector("[role=alert] li", text: "Enter a suffix for the application number")

    fill_in "Name", with: "Planning Permission - Major application"
    fill_in "Suffix", with: "MAJR"

    click_button "Continue"
    expect(page).to have_selector("h1", text: "Review the application type")
    expect(page).to have_selector("dl div:nth-child(1) dd", text: "Planning Permission - Major application")
    expect(page).to have_selector("dl div:nth-child(2) dd", text: "MAJR")
  end

  it "allows editing of an inactive application type" do
    application_type = create(:application_type, :ldc_proposed, status: "inactive")

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

    within "dl div:nth-child(3)" do
      expect(page).to have_selector("dd", text: "Inactive")
      click_link "Edit"
    end

    expect(page).to have_selector("h1", text: "Update status")

    choose "Active"
    click_button "Continue"

    expect(page).to have_selector("h1", text: "Review the application type")
    expect(page).to have_selector("dl div:nth-child(3) dd", text: "Active")
  end

  it "allows retirement of an application type" do
    application_type = create(:application_type, :ldc_proposed, status: "active")

    visit "/application_types/#{application_type.id}"
    expect(page).to have_selector("h1", text: "Review the application type")

    within "dl div:nth-child(3)" do
      expect(page).to have_selector("dd", text: "Active")
      click_link "Edit"
    end

    expect(page).to have_selector("h1", text: "Update status")
    expect(page).to have_no_field("Inactive")

    choose "Retired"
    click_button "Continue"

    expect(page).to have_selector("h1", text: "Review the application type")
    expect(page).to have_selector("dl div:nth-child(3) dd", text: "Retired")
  end

  it "allows an application type to be brought out of retirement" do
    application_type = create(:application_type, :ldc_proposed, status: "retired")

    visit "/application_types/#{application_type.id}"
    expect(page).to have_selector("h1", text: "Review the application type")

    within "dl div:nth-child(3)" do
      expect(page).to have_selector("dd", text: "Retired")
      click_link "Edit"
    end

    expect(page).to have_selector("h1", text: "Update status")
    expect(page).to have_no_field("Inactive")

    choose "Active"
    click_button "Continue"

    expect(page).to have_selector("h1", text: "Review the application type")
    expect(page).to have_selector("dl div:nth-child(3) dd", text: "Active")
  end
end
