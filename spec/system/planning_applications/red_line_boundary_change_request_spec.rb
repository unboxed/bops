# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Requesting map changes to a planning application", type: :system do
  let!(:assessor) { create :user, :assessor, local_authority: @default_local_authority }

  let!(:planning_application) do
    create :planning_application, :invalidated, local_authority: @default_local_authority
  end

  it "is possible to create a request to update map boundary" do
    sign_in assessor
    visit planning_application_path(planning_application)
    click_link "Validate application"
    click_link "Start new or view existing requests"
    click_link "Add new request"

    within("fieldset", text: "Send a change request") do
      choose "Request approval to a red line boundary change"
    end
    click_button "Next"

    fill_in "New geojson", with: "LatLng(51.501027, -0.077844),LatLng(51.501098, -0.077022),LatLng(51.500668, -0.076988),LatLng(51.500754, -0.077633),LatLng(51.500979, -0.077811)"
    fill_in "Explain to the applicant why changes are proposed to the red line boundary", with: "Coordinates look wrong"
    click_button "Send"

    expect(page).to have_content("Change request for red line boundary successfully sent.")
    expect(page).to have_link("View proposed red line boundary")
    expect(page).to have_content("Coordinates look wrong")

    click_link("View proposed red line boundary")
    expect(page).to have_content("Coordinates look wrong")
    expect(page).to have_content("Applicant's original red line boundary")

    email = ActionMailer::Base.deliveries.last
    expect(email.body).to have_content(planning_application.reference)
  end

  it "only accepts a request that contains updated coordinates" do
    sign_in assessor
    visit planning_application_path(planning_application)
    click_link "Validate application"
    click_link "Start new or view existing requests"
    click_link "Add new request"

    within("fieldset", text: "Send a change request") do
      choose "Request approval to a red line boundary change"
    end

    click_button "Next"

    fill_in "New geojson", with: " "
    click_button "Send"

    expect(page).to have_content("Red line drawing must be complete")
  end

  it "only accepts a request that contains a reason" do
    sign_in assessor
    visit planning_application_path(planning_application)
    click_link "Validate application"
    click_link "Start new or view existing requests"
    click_link "Add new request"

    within("fieldset", text: "Send a change request") do
      choose "Request approval to a red line boundary change"
    end

    click_button "Next"

    fill_in "Explain to the applicant why changes are proposed to the red line boundary", with: " "
    click_button "Send"

    expect(page).to have_content("Provide a reason for changes")
  end
end
