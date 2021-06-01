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

    fill_in "New geojson", with: '{"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[-0.07716178894042969,51.50094238217541],[-0.07645905017852783,51.50053497847238],[-0.07615327835083008,51.50115276135022],[-0.07716178894042969,51.50094238217541]]]}}'
    fill_in "Explain to the applicant why changes are proposed to the red line boundary", with: "Coordinates look wrong"
    click_button "Send"

    expect(page).to have_content("Change request for red line boundary successfully sent.")
    expect(page).to have_link("View proposed red line boundary")
    expect(page).to have_content("Coordinates look wrong")
  end
end
