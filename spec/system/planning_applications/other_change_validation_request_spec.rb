# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Requesting description changes to a planning application", type: :system do
  let!(:assessor) { create :user, :assessor, local_authority: @default_local_authority }

  let!(:planning_application) do
    create :planning_application, :invalidated, local_authority: @default_local_authority
  end

  before do
    travel_to Time.zone.local(2021, 1, 1)
    sign_in assessor
    visit planning_application_path(planning_application)
  end

  after do
    travel_back
  end

  it "is possible to create a request for miscellaneous changes" do
    click_link "Validate application"
    click_link "Start new or view existing validation requests"
    click_link "Add new request"

    choose "Request other change to application"
    click_button "Next"

    fill_in "Tell the applicant why the application is invalid", with: "The wrong fee has been paid"
    fill_in "Explain to the applicant how the application can be made valid", with: "You need to pay £100, which is the correct fee"
    click_button "Send"

    within(".change-requests") do
      expect(page).to have_content("Other")
      expect(page).to have_content("15 days")
    end

    click_link "Application"
    click_button "Key application dates"
    click_link "Activity log"

    expect(page).to have_text("Sent: validation request (other validation#1)")
    expect(page).to have_text("The wrong fee has been paid")
    expect(page).to have_text(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
  end

  it "only accepts a request that contains a summary and suggestion" do
    click_link "Validate application"
    click_link "Start new or view existing validation requests"
    click_link "Add new request"

    choose "Request other change to application"
    click_button "Next"

    fill_in "Tell the applicant why the application is invalid", with: ""
    fill_in "Explain to the applicant how the application can be made valid", with: ""
    click_button "Send"

    expect(page).to have_content("Summary can't be blank")
    expect(page).to have_content("Suggestion can't be blank")
  end

  it "lists the current change requests and their statuses" do
    create :other_change_validation_request, planning_application: planning_application, state: "open", created_at: 12.days.ago, summary: "Missing information", suggestion: "Please provide more details about ownership"
    create :other_change_validation_request, planning_application: planning_application, state: "closed", created_at: 12.days.ago, summary: "Fees outstanding", suggestion: "Please pay the balance", response: "paid"

    click_link "Validate application"
    click_link "Start new or view existing validation requests"

    within(".change-requests") do
      expect(page).to have_content("Missing information")
      expect(page).to have_content("Please provide more details about ownership")

      expect(page).to have_content("Fees outstanding")
      expect(page).to have_content("Please pay the balance")
      expect(page).to have_link("View response")

      expect(page).to have_content("6 days")
    end
  end

  it "only displays a new change request option if application is invalid" do
    planning_application.update!(status: "in_assessment")
    click_link "Validate application"

    expect(page).not_to have_content("Start new or view existing validation requests")
  end

  it "displays the details of the received request in the audit log" do
    create :audit, planning_application_id: planning_application.id, activity_type: "other_change_validation_request_received", activity_information: 1, audit_comment: { response: "I have sent the fee" }.to_json

    sign_in assessor
    visit planning_application_path(planning_application)

    click_button "Key application dates"
    click_link "Activity log"

    expect(page).to have_text("Received: request for change (other validation#1)")
    expect(page).to have_text("I have sent the fee")
  end
end
