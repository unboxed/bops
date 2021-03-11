# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Creating a planning application", type: :system do
  let!(:assessor1) { create :user, :assessor, local_authority: @default_local_authority, name: "Assessor 1" }
  let!(:reviewer1) { create :user, :reviewer, local_authority: @default_local_authority, name: "Reviewer 1" }

  before do
    sign_in assessor1
    visit root_path
  end

  it "prevents a logged out user from accessing the form" do
    click_button "Log out"
    visit new_planning_application_path(@default_local_authority)

    expect(page).to have_text("You need to sign in or sign up before continuing.")
  end

  it "allows for an application to be created by an assessor, using minimum details" do
    click_link "Add new application"

    expect(page).to have_text("New Application: Residential Lawful Development Certificate")

    fill_in "Summary of work", with: "Back shack"
    click_button "Save"
    expect(page).to have_text("Planning application was successfully created.")

    visit planning_application_path(PlanningApplication.last.id)
    expect(page).to have_text("Summary: Back shack")
  end

  it "allows for an application to be created by a reviewer, using minimum details" do
    click_button "Log out"
    sign_in reviewer1
    visit root_path

    click_link "Add new application"

    fill_in "Summary of work", with: "Bird house"
    click_button "Save"
    expect(page).to have_text("Planning application was successfully created.")

    visit planning_application_path(PlanningApplication.last.id)
    expect(page).to have_text("Summary: Bird house")

    visit planning_application_path(PlanningApplication.last.id)
    click_button "Key application dates"
    click_link "Activity log"

    expect(page).to have_text("Application created by Reviewer 1")
  end

  context "it allows for a full application to be completed" do
    before do
      click_link "Add new application"

      fill_in "Summary of work", with: "Backyard bird hotel"
      fill_in "Day", with: "3"
      fill_in "Month", with: "3"
      fill_in "Year", with: "2021"
      fill_in "Address 1", with: "Palace Road"
      fill_in "Address 2", with: "456"
      fill_in "Town", with: "Crystal Palace"
      fill_in "County", with: "London"
      fill_in "Postcode", with: "SE19 2LX"
      fill_in "UPRN", with: "19284783939"

      within ".applicant-information" do
        fill_in "First name", with: "Carlota"
        fill_in "Last name", with: "Corlita"
        fill_in "Email address", with: "carlota@corlita.com"
        fill_in "UK telephone number", with: "0777773949494312"
      end

      within ".agent-information" do
        fill_in "First name", with: "Agentina"
        fill_in "Last name", with: "Agentino"
        fill_in "Email address", with: "agentina@agentino.com"
        fill_in "UK telephone number", with: "923838484492939"
      end

      fill_in "Payment reference", with: "232432544"
    end

    it "with default proposed status if no status is selected" do
      click_button "Save"

      expect(page).to have_text("Planning application was successfully created.")

      visit planning_application_path(PlanningApplication.last.id)

      expect(page).to have_text("Address: Palace Road, Crystal Palace, SE19 2LX")
      expect(page).to have_text("UPRN: 19284783939")
      expect(page).to have_text("Proposed permitted development: Certificate of Lawfulness")
      expect(page).to have_text("Work already completed: No")
      expect(page).to have_text("Summary: Backyard bird hotel")
      expect(page).to have_text("Payment Reference: 232432544")
      expect(page).to have_text("Agentina Agentino")
      expect(page).to have_text("agentina@agentino.com")
      expect(page).to have_text("923838484492939")
      expect(page).to have_text("Carlota Corlita")
      expect(page).to have_text("carlota@corlita.com")
      expect(page).to have_text("0777773949494312")
    end

    it "with existing status" do
      within "form", text: "Has the work been completed?" do
        choose "Yes"
      end

      click_button "Save"

      visit planning_application_path(PlanningApplication.last.id)

      expect(page).to have_text("Work already completed: Yes")
    end

    it "with the create action being correctly audited" do
      click_button "Save"

      visit planning_application_path(PlanningApplication.last.id)
      click_button "Key application dates"
      click_link "Activity log"

      expect(page).to have_text("Application created by Assessor 1")
    end
  end
end
