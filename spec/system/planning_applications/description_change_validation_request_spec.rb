# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Requesting description changes to a planning application", type: :system do
  let!(:assessor) { create :user, :assessor, local_authority: @default_local_authority }

  let!(:planning_application) do
    create :planning_application, :not_started, local_authority: @default_local_authority
  end

  let!(:api_user) { create :api_user, name: "Api Wizard" }

  before do
    travel_to Time.zone.local(2021, 1, 1)
    sign_in assessor
    visit planning_application_path(planning_application)
  end

  it "is possible to create a request to update description" do
    visit new_planning_application_description_change_validation_request_path(planning_application)

    fill_in "Please suggest a new application description", with: "New description"
    click_button "Send"

    expect(page).to have_text("Description change request successfully sent.")

    click_button "Key application dates"
    click_link "Activity log"

    expect(page).to have_text("Sent: description change request (description#1)")
    expect(page).to have_text(planning_application.description)
    expect(page).to have_text("Proposed description")
    expect(page).to have_text(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
  end

  it "only accepts a request that contains a proposed description" do
    visit new_planning_application_description_change_validation_request_path(planning_application)

    fill_in "Please suggest a new application description", with: " "
    click_button "Send"

    expect(page).to have_content("Proposed description can't be blank")
  end
end
