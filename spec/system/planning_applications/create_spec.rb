# frozen_string_literal: true

require "rails_helper"
require "faraday"

RSpec.describe "Creating a planning application" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor1) { create(:user, :assessor, local_authority: default_local_authority, name: "Assessor 1") }
  let!(:reviewer1) { create(:user, :reviewer, local_authority: default_local_authority, name: "Reviewer 1") }
  let!(:ldc_existing) { create(:application_type, :ldc_existing) }
  let!(:ldc_proposed) { create(:application_type, :ldc_proposed) }

  before do
    sign_in assessor1
    visit "/"
  end

  it "prevents a logged out user from accessing the form" do
    click_link "Log out"
    visit "/planning_applications/new"

    expect(page).to have_text("You need to sign in or sign up before continuing.")
  end

  it "allows for an application to be created by an assessor, using minimum details" do
    click_link "Add new application"

    expect(page).to have_text("New Application")

    select("Lawful Development Certificate - Proposed use")
    fill_in "Description", with: "Back shack"

    within_fieldset "Applicant information" do
      fill_in "Email address", with: "thesebeans@thesebeans.com"
    end

    click_button "Save"
    expect(page).to have_text("Planning application was successfully created.")

    visit "/planning_applications/#{PlanningApplication.last.id}"
    click_link("Check and validate")
    expect(page).to have_text("Description: Back shack")
  end

  it "displays an error when both agent and applicant emails are missing" do
    click_link "Add new application"

    select("Lawful Development Certificate - Proposed use")
    fill_in "Description", with: "Bad bad application"

    click_button "Save"
    expect(page).to have_text("An applicant or agent email is required.")

    within_fieldset "Agent information" do
      fill_in "Email address", with: "agentina@agentino.com"
    end
    click_button "Save"

    visit "/planning_applications/#{PlanningApplication.last.id}"
    click_link("Check and validate")
    expect(page).to have_text("Description: Bad bad application")
  end

  it "displays an error when application type is not selected" do
    click_link "Add new application"

    click_button "Save"
    expect(page).to have_text("Application type must exist")
  end

  it "allows for an application to be created by a reviewer, using minimum details" do
    click_link "Log out"
    sign_in reviewer1
    visit "/"

    click_link "Add new application"

    select("Lawful Development Certificate - Proposed use")
    fill_in "Description", with: "Bird house"
    within_fieldset "Applicant information" do
      fill_in "Email address", with: "mah@mah.com"
    end

    click_button "Save"
    expect(page).to have_text("Planning application was successfully created.")

    visit "/planning_applications/#{PlanningApplication.last.id}"
    click_link("Check and validate")
    expect(page).to have_text("Description: Bird house")
  end

  context "when it allows a full application to be completed" do
    before do
      click_link "Add new application"

      select("Lawful Development Certificate - Proposed use")
      fill_in "Description", with: "Backyard bird hotel"
      fill_in "Day", with: "3"
      fill_in "Month", with: "3"
      fill_in "Year", with: "2021"

      find("span", text: "Add address manually").click

      fill_in "Address 1", with: "Palace Road"
      fill_in "Address 2", with: "456"
      fill_in "Town", with: "Crystal Palace"
      fill_in "County", with: "London"
      fill_in "Postcode", with: "SE19 2LX"
      fill_in "UPRN", with: "19284783939"

      within_fieldset "Applicant information" do
        fill_in "First name", with: "Carlota"
        fill_in "Last name", with: "Corlita"
        fill_in "Email address", with: "carlota@corlita.com"
        fill_in "UK telephone number", with: "0777773949494312"
      end

      within_fieldset "Agent information" do
        fill_in "First name", with: "Agentina"
        fill_in "Last name", with: "Agentino"
        fill_in "Email address", with: "agentina@agentino.com"
        fill_in "UK telephone number", with: "923838484492939"
      end

      fill_in "Payment reference", with: "232432544"
      fill_in "planning_application[payment_amount]", with: "104.00"
    end

    it "with default proposed status if no status is selected" do
      click_button "Save"

      expect(page).to have_text("Planning application was successfully created.")

      visit "/planning_applications/#{PlanningApplication.last.id}"

      expect(page).to have_text("Agentina Agentino")
      expect(page).to have_text("agentina@agentino.com")
      expect(page).to have_text("923838484492939")
      expect(page).to have_text("Carlota Corlita")
      expect(page).to have_text("carlota@corlita.com")
      expect(page).to have_text("0777773949494312")

      click_link("Check and validate")

      expect(page).to have_text("Site address: Palace Road, Crystal Palace, SE19 2LX")
      expect(page).to have_text("UPRN: 19284783939")
      expect(page).to have_text("Application type: Lawful Development Certificate - Proposed")
      expect(page).to have_text("Work already started: No")
      expect(page).to have_text("Description: Backyard bird hotel")
    end

    it "has the correct format for payment amount in pounds" do
      click_button "Save"

      visit "/planning_applications/#{PlanningApplication.last.id}"
      click_link("Check and validate")
      click_button "Application information"
      click_link "Edit details"

      expect(page).to have_field("planning_application[payment_amount]", with: "104.00")
    end
  end

  it "can fill in details using address lookup", js: true do
    allow_any_instance_of(Faraday::Connection).to receive(:get).and_return(instance_double(Faraday::Response, status: 200, body: "some data"))
    allow_any_instance_of(Apis::OsPlaces::Query).to receive(:find_addresses).and_return(Faraday.new.get)
    allow_any_instance_of(PlanningApplication).to receive(:set_ward_and_parish_information).and_return(true)

    allow_any_instance_of(Apis::OsPlaces::Query).to receive(:find_addresses)
      .with("60-")
      .and_return(instance_double(Faraday::Response, status: 200, body: {header: {}, results: [{DPA: {ADDRESS: "60-62, Commercial Street, LONDON, E16LT"}}]}))

    click_link "Add new application"

    select("Lawful Development Certificate - Proposed use")
    fill_in "Description", with: "Backyard bird hotel"
    fill_in "Day", with: "3"
    fill_in "Month", with: "3"
    fill_in "Year", with: "2021"

    fill_in "Search for address", with: "60-"

    page.find(:xpath, "//li[text()='60-62, Commercial Street, LONDON, E16LT']").click

    allow_any_instance_of(Apis::OsPlaces::Query).to receive(:find_addresses)
      .with("60-62, Commercial Street, LONDON, E16LT")
      .and_return(instance_double(Faraday::Response, status: 200, body: {header: {}, results: [{DPA: {ADDRESS: "60-62, Commercial Street, LONDON, E16LT", POST_TOWN: "LONDON", POSTCODE: "E16LT", LNG: 0.1, LAT: 51, UPRN: "1234"}}]}))

    within_fieldset "Applicant information" do
      fill_in "First name", with: "Carlota"
      fill_in "Last name", with: "Corlita"
      fill_in "Email address", with: "carlota@corlita.com"
      fill_in "UK telephone number", with: "0777773949494312"
    end

    click_button "Save"

    expect(page).to have_text("Planning application was successfully created.")

    visit "/planning_applications/#{PlanningApplication.last.id}"

    click_link("Check and validate")

    expect(page).to have_text("Site address: 60-62, Commercial Street, LONDON, E16LT")
    expect(page).to have_text("UPRN: 1234")

    expect(PlanningApplication.last.lonlat).to eq(RGeo::Geographic.spherical_factory(srid: 4326).point("0.1", "51"))
  end
end
