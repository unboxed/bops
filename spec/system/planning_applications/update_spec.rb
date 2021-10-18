# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Updating a planning application", type: :system do
  let!(:assessor1) { create :user, :assessor, local_authority: @default_local_authority, name: "Assessor 1" }
  let!(:planning_application) do
    create :planning_application,
           :not_started,
           local_authority: @default_local_authority,
           user: assessor1,
           address_1: "1 golden street",
           address_2: "Southwark"
  end

  before do
    sign_in assessor1
    visit planning_application_path(planning_application)
    click_button "Application information"
    click_link "Edit details"
  end

  it "is possible to edit the date received in" do
    fill_in "Day", with: "3"
    fill_in "Month", with: "10"
    fill_in "Year", with: "1989"

    click_button "Save"
    planning_application.reload

    expect(page).to have_text("Target date: 21 November 1989")
  end

  it "is possible to edit site details" do
    fill_in "Address 1", with: "2 Streatham High Road"
    fill_in "Address 2", with: "Streatham"
    fill_in "Town", with: "Crystal Palace"
    fill_in "County", with: "London"
    fill_in "Postcode", with: "SW16 1DB"
    fill_in "UPRN", with: "294884040"

    click_button "Save"
    planning_application.reload
    click_button "Application information"

    expect(page).to have_text("Site address: 2 Streatham High Road, Crystal Palace, SW16 1DB")
    expect(page).to have_text("UPRN: 294884040")
  end

  it "is possible to edit proposed or completed status" do
    within "form", text: "Has the work been started?" do
      choose "Yes"
    end

    click_button "Save"
    click_button "Application information"

    expect(page).to have_text("Work already started: Yes")
  end

  it "is possible to edit applicant information" do
    within ".applicant-information" do
      fill_in "First name", with: "Pearly"
      fill_in "Last name", with: "Poorly"
      fill_in "Email address", with: "pearly@poorly.com"
      fill_in "UK telephone number", with: "0777773949494312"
    end

    click_button "Save"
    click_button "Application information"

    expect(page).to have_text("Pearly Poorly")
    expect(page).to have_text("pearly@poorly.com")
    expect(page).to have_text("0777773949494312")
  end

  it "is possible to edit agent information" do
    within ".agent-information" do
      fill_in "First name", with: "Agentina"
      fill_in "Last name", with: "Agentino"
      fill_in "Email address", with: "agentina@agentino.com"
      fill_in "UK telephone number", with: "923838484492939"
    end

    click_button "Save"
    click_button "Application information"

    expect(page).to have_text("Agentina Agentino")
    expect(page).to have_text("agentina@agentino.com")
    expect(page).to have_text("923838484492939")
  end

  it "is possible to edit the payment reference" do
    fill_in "Payment reference", with: "293844848"
    click_button "Save"
    click_button "Application information"

    expect(page).to have_text("293844848")
  end
end
