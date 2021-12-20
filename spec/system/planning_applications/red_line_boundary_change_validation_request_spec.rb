# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Requesting map changes to a planning application", type: :system do
  let!(:assessor) { create :user, :assessor, local_authority: @default_local_authority }

  let!(:planning_application) do
    create :planning_application, :invalidated, local_authority: @default_local_authority
  end

  let!(:api_user) { create :api_user, name: "Api Wizard" }

  it "is possible to create a request to update map boundary" do
    delivered_emails = ActionMailer::Base.deliveries.count
    sign_in assessor
    visit planning_application_path(planning_application)
    click_link "Validate application"
    click_link "Start new or view existing requests"
    click_link "Add new request"

    within("fieldset", text: "Add a validation request") do
      choose "Request approval to a red line boundary change"
    end
    click_button "Next"

    find(".govuk-visually-hidden",
         visible: false).set '{"type":"Feature","properties":{},"geometry":{"type":"Polygon","coordinates":[[[-0.076715,51.501166],[-0.07695,51.500673],[-0.076,51.500763],[-0.076715,51.501166]]]}}'
    fill_in "Explain to the applicant why changes are proposed to the red line boundary", with: "Coordinates look wrong"
    click_button "Add"

    expect(page).to have_content("Validation request for red line boundary successfully created.")
    expect(page).to have_link("View proposed red line boundary")
    expect(page).to have_content("Coordinates look wrong")

    click_link("View proposed red line boundary")
    expect(page).to have_content("Coordinates look wrong")
    expect(ActionMailer::Base.deliveries.count).to eql(delivered_emails + 1)
  end

  it "only accepts a request that contains updated coordinates" do
    sign_in assessor
    visit planning_application_path(planning_application)
    click_link "Validate application"
    click_link "Start new or view existing requests"
    click_link "Add new request"

    within("fieldset", text: "Add a validation request") do
      choose "Request approval to a red line boundary change"
    end

    click_button "Next"

    find(".govuk-visually-hidden", visible: false).set ""
    click_button "Add"

    expect(page).to have_content("Red line drawing must be complete")
  end

  it "only accepts a request that contains a reason" do
    sign_in assessor
    visit planning_application_path(planning_application)

    click_link "Validate application"
    click_link "Start new or view existing requests"

    click_link "Add new request"

    within("fieldset", text: "Add a validation request") do
      choose "Request approval to a red line boundary change"
    end

    click_button "Next"

    fill_in "Explain to the applicant why changes are proposed to the red line boundary", with: " "
    click_button "Add"

    expect(page).to have_content("Provide a reason for changes")
  end
end
