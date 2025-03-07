# frozen_string_literal: true

require "rails_helper"
require "faraday"

RSpec.describe "Creating a planning application", type: :system do
  let!(:local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: local_authority) }
  let!(:reviewer) { create(:user, :reviewer, local_authority: local_authority) }
  let!(:ldc_existing) { create(:application_type, :ldc_existing, local_authority: local_authority) }
  let!(:ldc_proposed) { create(:application_type, :ldc_proposed, local_authority: local_authority) }

  let!(:subdomain) { local_authority.subdomain }
  let!(:planning_applications) { local_authority.planning_applications }
  let!(:planning_application) { planning_applications.new }

  let(:reference) { planning_application.reference }

  before do
    allow(LocalAuthority).to receive(:find_by).with(subdomain:).and_return(local_authority)
    allow(local_authority).to receive(:planning_applications).and_return(planning_applications)
    allow(planning_applications).to receive(:new).and_return(planning_application)
  end

  context "when logged out" do
    it "prevents a user from accessing the form" do
      visit "/planning_applications/new"
      expect(page).to have_content("You need to sign in or sign up before continuing")
    end
  end

  context "when logged in an assessor" do
    before do
      sign_in assessor

      visit "/planning_applications/new"
      expect(page).to have_current_path("/planning_applications/new")
      expect(page).to have_selector("h1", text: "New Application")
    end

    it "allows for an application to be created using the minimum details" do
      select("Lawful Development Certificate - Proposed use")
      fill_in "Description", with: "Back shack"

      within_fieldset "Applicant information" do
        fill_in "Email address", with: "thesebeans@thesebeans.com"
      end

      click_button "Save"
      expect(page).to have_current_path("/planning_applications/#{reference}/documents")
      expect(page).to have_content("Planning application was successfully created.")

      visit "/planning_applications/#{reference}"
      expect(page).to have_content("Description: Back shack")
    end

    it "displays an error when application type is not selected" do
      click_button "Save"
      expect(page).to have_current_path("/planning_applications")
      expect(page).to have_selector("[role=alert] li", text: "An application type must be chosen")
    end

    it "displays an error when both agent and applicant emails are missing" do
      select("Lawful Development Certificate - Proposed use")
      fill_in "Description", with: "Bad bad application"

      click_button "Save"
      expect(page).to have_current_path("/planning_applications")
      expect(page).to have_selector("[role=alert] li", text: "An applicant or agent email is required.")

      within_fieldset "Agent information" do
        fill_in "Email address", with: "agentina@agentino.com"
      end

      click_button "Save"
      expect(page).to have_current_path("/planning_applications/#{reference}/documents")
      expect(page).to have_content("Planning application was successfully created.")

      visit "/planning_applications/#{reference}"
      expect(page).to have_content("Description: Bad bad application")
    end

    it "displays an error with an invalid email address" do
      within_fieldset "Agent information" do
        fill_in "Email address", with: "invalid-agent-email"
      end

      within_fieldset "Applicant information" do
        fill_in "Email address", with: "invalid-applicant-email"
      end

      click_button "Save"
      expect(page).to have_current_path("/planning_applications")
      expect(page).to have_selector("[role=alert] li", text: "Agent email is invalid")
      expect(page).to have_selector("[role=alert] li", text: "Applicant email is invalid")
    end

    context "and completing a full application" do
      before do
        select("Lawful Development Certificate - Proposed use")
        fill_in "Description", with: "Backyard bird hotel"
        fill_in "Day", with: "3"
        fill_in "Month", with: "3"
        fill_in "Year", with: "2021"

        toggle "Add address manually"

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

      it "has a default status of 'proposed'" do
        click_button "Save"
        expect(page).to have_current_path("/planning_applications/#{reference}/documents")
        expect(page).to have_content("Planning application was successfully created.")

        visit "/planning_applications/#{reference}"
        expect(page).to have_current_path("/planning_applications/#{reference}")

        expect(page).to have_content("Agentina Agentino")
        expect(page).to have_content("agentina@agentino.com")
        expect(page).to have_content("923838484492939")
        expect(page).to have_content("Carlota Corlita")
        expect(page).to have_content("carlota@corlita.com")
        expect(page).to have_content("0777773949494312")

        expect(page).to have_content("Site address: Palace Road, Crystal Palace, SE19 2LX")
        expect(page).to have_content("UPRN: 19284783939")
        expect(page).to have_content("Application type: Lawful Development Certificate - Proposed")
        expect(page).to have_content("Work already started: No")
        expect(page).to have_content("Description: Backyard bird hotel")
      end

      it "has the correct format for the payment amount" do
        click_button "Save"
        expect(page).to have_current_path("/planning_applications/#{reference}/documents")
        expect(page).to have_content("Planning application was successfully created.")

        visit "/planning_applications/#{reference}"
        expect(page).to have_current_path("/planning_applications/#{reference}")
        expect(page).to have_selector("h1", text: "Application")

        toggle "Application information"

        within(:open_accordion) do
          click_link "Edit details"
        end

        expect(page).to have_current_path("/planning_applications/#{reference}/edit")
        expect(page).to have_field("Payment amount", with: "104.00")
      end
    end

    context "and using the address lookup" do
      let(:query) { instance_double("Apis::OsPlaces::Query") }
      let(:response) { instance_double("Faraday::Response") }

      let(:addresses) do
        {
          header: {},
          results: [
            {DPA: {ADDRESS: "60-62, Commercial Street, LONDON, E16LT", UPRN: "1234", LNG: 0.1, LAT: 51}}
          ]
        }
      end

      before do
        allow(Apis::OsPlaces::Query).to receive(:new).and_return(query)
        allow(query).to receive(:find_addresses).with(a_string_matching(/^60-/)).and_return(response)
        allow(response).to receive(:body).and_return(addresses)
      end

      it "can create an application", js: true do
        select("Lawful Development Certificate - Proposed use")
        fill_in "Description", with: "Backyard bird hotel"
        fill_in "Day", with: "3"
        fill_in "Month", with: "3"
        fill_in "Year", with: "2021"

        fill_in "Search for address", with: "60-62 Commercial Street"
        pick "60-62, Commercial Street, LONDON, E16LT", from: "#address"

        within_fieldset "Applicant information" do
          fill_in "First name", with: "Carlota"
          fill_in "Last name", with: "Corlita"
          fill_in "Email address", with: "carlota@corlita.com"
          fill_in "UK telephone number", with: "0777773949494312"
        end

        click_button "Save"
        expect(page).to have_current_path(%r[^/planning_applications/\d{2}-\d{5}-LDCP/documents])
        expect(page).to have_content("Planning application was successfully created.")

        visit "/planning_applications/#{reference}"

        expect(page).to have_content("Site address: 60-62, Commercial Street, LONDON, E16LT")
        expect(page).to have_content("UPRN: 1234")

        expect(planning_application).to have_attributes(longitude: "0.1", latitude: "51")
      end
    end
  end

  context "when logged in as a reviewer" do
    before do
      sign_in reviewer

      visit "/planning_applications/new"
      expect(page).to have_current_path("/planning_applications/new")
      expect(page).to have_selector("h1", text: "New Application")
    end

    it "allows for an application to be created using the minimum details" do
      select("Lawful Development Certificate - Proposed use")
      fill_in "Description", with: "Bird house"

      within_fieldset "Applicant information" do
        fill_in "Email address", with: "thesebeans@thesebeans.com"
      end

      click_button "Save"
      expect(page).to have_current_path("/planning_applications/#{reference}/documents")
      expect(page).to have_content("Planning application was successfully created.")

      visit "/planning_applications/#{reference}"
      expect(page).to have_content("Description: Bird house")
    end
  end
end
