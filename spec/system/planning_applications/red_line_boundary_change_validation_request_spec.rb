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
    click_link "Start new or view existing validation requests"
    click_link "Add new request"

    within("fieldset", text: "Send a validation request") do
      choose "Request approval to a red line boundary change"
    end
    click_button "Next"

    find(".govuk-visually-hidden", visible: false).set '{"type":"Feature","properties":{},"geometry":{"type":"Polygon","coordinates":[[[-0.076715,51.501166],[-0.07695,51.500673],[-0.076,51.500763],[-0.076715,51.501166]]]}}'
    fill_in "Explain to the applicant why changes are proposed to the red line boundary", with: "Coordinates look wrong"
    click_button "Send"

    expect(page).to have_content("Validation request for red line boundary successfully sent.")
    expect(page).to have_link("View proposed red line boundary")
    expect(page).to have_content("Coordinates look wrong")

    click_link("View proposed red line boundary")
    expect(page).to have_content("Coordinates look wrong")

    click_link "Application"
    click_button "Key application dates"
    click_link "Activity log"

    expect(page).to have_text("Sent: validation request (red line boundary#1)")
    expect(page).to have_text("Coordinates look wrong")
    expect(page).to have_text(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))

    email = ActionMailer::Base.deliveries.last
    expect(email.body).to have_content(planning_application.reference)
  end

  it "only accepts a request that contains updated coordinates" do
    sign_in assessor
    visit planning_application_path(planning_application)
    click_link "Validate application"
    click_link "Start new or view existing validation requests"
    click_link "Add new request"

    within("fieldset", text: "Send a validation request") do
      choose "Request approval to a red line boundary change"
    end

    click_button "Next"

    find(".govuk-visually-hidden", visible: false).set ""
    click_button "Send"

    expect(page).to have_content("Red line drawing must be complete")
  end

  it "only accepts a request that contains a reason" do
    sign_in assessor
    visit planning_application_path(planning_application)
    click_link "Validate application"
    click_link "Start new or view existing validation requests"
    click_link "Add new request"

    within("fieldset", text: "Send a validation request") do
      choose "Request approval to a red line boundary change"
    end

    click_button "Next"

    fill_in "Explain to the applicant why changes are proposed to the red line boundary", with: " "
    click_button "Send"

    expect(page).to have_content("Provide a reason for changes")
  end
end
