# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Requesting description changes to a planning application", type: :system do
  let!(:assessor) { create :user, :assessor, local_authority: @default_local_authority }

  let!(:planning_application) do
    create :planning_application, :invalidated, local_authority: @default_local_authority
  end

  let!(:description_change_request) do
    create :description_change_request, planning_application: planning_application, state: "open", created_at: 12.days.ago
  end

  before do
    travel_to Time.zone.local(2021, 1, 1)
    sign_in assessor
    visit planning_application_path(planning_application)
  end

  after do
    travel_back
  end

  it "is possible to create a request to update description" do
    click_link "Validate application"
    click_link "Start new or view existing requests"
    click_link "Add new request"

    within("fieldset", text: "Send a change request") do
      choose "Request approval to a description change"
    end
    click_button "Next"

    fill_in "Please suggest a new application description", with: "New description"
    click_button "Send"

    within(".change-requests") do
      expect(page).to have_content("Description")
      expect(page).to have_content("15 days")
    end

    click_link "Application"
    click_button "Key application dates"
    click_link "Activity log"

    expect(page).to have_text("Sent: Request for change (description")
    expect(page).to have_text(planning_application.description)
    expect(page).to have_text("New description")
    expect(page).to have_text(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
  end

  it "only accepts a request that contains a proposed description" do
    click_link "Validate application"
    click_link "Start new or view existing requests"
    click_link "Add new request"

    within("fieldset", text: "Send a change request") do
      choose "Request approval to a description change"
    end

    click_button "Next"

    fill_in "Please suggest a new application description", with: " "
    click_button "Send"

    expect(page).to have_content("Proposed description can't be blank")
  end

  it "lists the current change requests and their statuses" do
    create :description_change_request, planning_application: planning_application, state: "open", created_at: 12.days.ago
    create :description_change_request, planning_application: planning_application, state: "closed", created_at: 12.days.ago, approved: true
    create :description_change_request, planning_application: planning_application, state: "closed", created_at: 12.days.ago, approved: false, rejection_reason: "No good"
    create :description_change_request, planning_application: planning_application, state: "open", created_at: 35.days.ago

    click_link "Validate application"
    click_link "Start new or view existing requests"

    within(".change-requests") do
      expect(page).to have_content("Rejected")
      expect(page).to have_content("No good")

      expect(page).to have_content("Accepted")
      expect(page).to have_content("Description change has been approved by the applicant")

      expect(page).to have_content("6 days")
      expect(page).to have_content("-10 days")
    end
  end

  it "only displays a new change request option if application is invalid" do
    planning_application.update!(status: "in_assessment")
    click_link "Validate application"

    expect(page).not_to have_content("Start new or view existing requests")
  end
end
