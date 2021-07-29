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
    click_link "Start new or view existing validation requests"
    click_link "Add new request"

    within("fieldset", text: "Send a validation request") do
      choose "Request approval to a red line boundary change"
    end
    click_button "Next"

    find(".govuk-visually-hidden", visible: false).set '{"type":"Feature","properties":{},"geometry":{"type":"Polygon","coordinates":[[[-0.076715,51.501166],[-0.07695,51.500673],[-0.076,51.500763],[-0.076715,51.501166]]]}}'
    fill_in "Explain to the applicant why changes are proposed to the red line boundary", with: "Coordinates look wrong"
    click_button "Send"

    expect(page).to have_content("Validation request for red line boundary successfully created.")
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
    expect(ActionMailer::Base.deliveries.count).to eql(delivered_emails)
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

  it "displays the details of the received request in the audit log" do
    create :audit, planning_application_id: planning_application.id, activity_type: "red_line_boundary_change_validation_request_received", activity_information: 1, audit_comment: { response: "rejected", reason: "The boundary was too small" }.to_json, api_user: api_user

    sign_in assessor
    visit planning_application_path(planning_application)

    click_button "Key application dates"
    click_link "Activity log"

    expect(page).to have_text("Received: request for change (red line boundary#1)")
    expect(page).to have_text("The boundary was too small")
    expect(page).to have_text("rejected")
    expect(page).to have_text("Applicant / Agent via Api Wizard")
  end

  it "updates the notified_at date of an open request when application is invalidated" do
    new_planning_application = create :planning_application, :not_started, local_authority: @default_local_authority
    request = create :red_line_boundary_change_validation_request, planning_application: new_planning_application, state: "open", created_at: 12.days.ago

    sign_in assessor
    visit planning_application_path(new_planning_application)
    click_link "Validate application"

    click_link "Start new or view existing validation requests"
    expect(request.notified_at.class).to eql(NilClass)

    click_button "Invalidate application"

    expect(page).to have_content("Application has been invalidated")

    new_planning_application.reload
    expect(new_planning_application.status).to eq("invalidated")

    request.reload
    expect(request.notified_at.class).to eql(Date)
  end
end
