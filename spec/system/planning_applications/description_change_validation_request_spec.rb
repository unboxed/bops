# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Requesting description changes to a planning application", type: :system do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create :user, :assessor, local_authority: default_local_authority }

  let!(:planning_application) do
    create :planning_application, :not_started, local_authority: default_local_authority
  end

  let!(:api_user) { create :api_user, name: "Api Wizard" }

  before do
    travel_to Time.zone.local(2021, 1, 1)
    sign_in assessor
    visit planning_application_path(planning_application)
  end

  it "displays the planning application address and reference" do
    click_button "Application information"
    click_link "Propose a change to the description"

    expect(page).to have_content(planning_application.full_address.upcase)
    expect(page).to have_content(planning_application.reference)
  end

  it "is possible to create a request to update description" do
    visit new_planning_application_description_change_validation_request_path(planning_application)

    fill_in "Please suggest a new application description", with: "New description"
    click_button "Send"

    expect(page).to have_text("Description change request successfully sent.")
  end

  it "only accepts a request that contains a proposed description" do
    visit new_planning_application_description_change_validation_request_path(planning_application)

    fill_in "Please suggest a new application description", with: " "
    click_button "Send"

    expect(page).to have_content("Proposed description can't be blank")
  end

  context "when planning application is closed" do
    let!(:planning_application) do
      create :planning_application, :closed, local_authority: default_local_authority
    end

    it "does not show a link to creating a description change request" do
      visit planning_application_path(planning_application)

      click_button "Application information"

      expect(page).not_to have_link("Propose a change to the description")
    end
  end

  context "when planning application is not closed" do
    it "shows a link to creating a description change request" do
      visit planning_application_path(planning_application)

      click_button "Application information"

      expect(page).to have_link("Propose a change to the description")
    end
  end
end
