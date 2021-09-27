# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Requesting description changes to a planning application", type: :system do
  let!(:assessor) { create :user, :assessor, local_authority: @default_local_authority }

  let!(:planning_application) do
    create :planning_application, :invalidated, local_authority: @default_local_authority
  end

  let!(:description_change_validation_request) do
    create :description_change_validation_request, planning_application: planning_application, state: "open", created_at: 12.days.ago
  end

  let!(:api_user) { create :api_user, name: "Api Wizard" }

  before do
    travel_to Time.zone.local(2021, 1, 1)
    sign_in assessor
    visit planning_application_path(planning_application)
  end

  after do
    travel_back
  end

  it "is possible to create a request to update description" do
    delivered_emails = ActionMailer::Base.deliveries.count
    click_link "Validate application"
    click_link "Start new or view existing requests"
    click_link "Add new request"

    within("fieldset", text: "Send a validation request") do
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

    expect(page).to have_text("Sent: validation request (description#2)")
    expect(page).to have_text(planning_application.description)
    expect(page).to have_text("New description")
    expect(page).to have_text(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
    expect(ActionMailer::Base.deliveries.count).to eql(delivered_emails + 1)
  end

  it "only accepts a request that contains a proposed description" do
    click_link "Validate application"
    click_link "Start new or view existing requests"
    click_link "Add new request"

    within("fieldset", text: "Send a validation request") do
      choose "Request approval to a description change"
    end

    click_button "Next"

    fill_in "Please suggest a new application description", with: " "
    click_button "Send"

    expect(page).to have_content("Proposed description can't be blank")
  end

  it "lists the current validation requests and their statuses" do
    create :description_change_validation_request, planning_application: planning_application, state: "open", created_at: 12.days.ago, notified_at: 12.days.ago
    create :description_change_validation_request, planning_application: planning_application, state: "closed", created_at: 12.days.ago, notified_at: 12.days.ago, approved: true
    create :description_change_validation_request, planning_application: planning_application, state: "closed", created_at: 12.days.ago, notified_at: 12.days.ago, approved: false, rejection_reason: "No good"
    create :description_change_validation_request, planning_application: planning_application, state: "open", created_at: 35.days.ago, notified_at: 35.days.ago
    create :audit, planning_application_id: planning_application.id, activity_type: "description_change_validation_request_received", activity_information: 1, audit_comment: { response: "approved" }.to_json, api_user: api_user

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

    click_link "Application"
    click_button "Key application dates"
    click_link "Activity log"

    expect(page).to have_text("Received: request for change (description#1)")
    expect(page).to have_text("approved")
    expect(page).to have_text("Applicant / Agent via Api Wizard")
  end

  context "Invalidation updates description change validation request" do
    it "updates the notified_at date of an open request when application is invalidated" do
      new_planning_application = create :planning_application, :not_started, local_authority: @default_local_authority
      request = create :description_change_validation_request, planning_application: new_planning_application, state: "open", created_at: 12.days.ago

      visit planning_application_path(new_planning_application)
      click_link "Validate application"

      click_link "Request validation changes"
      expect(request.notified_at.class).to eql(NilClass)

      click_button "Invalidate application"

      expect(page).to have_content("Application has been invalidated")

      new_planning_application.reload
      expect(new_planning_application.status).to eq("invalidated")

      request.reload
      expect(request.notified_at.class).to eql(Date)
    end
  end

  context "Sending requests after application is invalidated" do
    it "allows the planning officer to create and send a validation request while application is invalid" do
      invalid_planning_application = create :planning_application, :invalidated, local_authority: @default_local_authority
      delivered_emails = ActionMailer::Base.deliveries.count

      visit planning_application_path(invalid_planning_application)
      click_link "Validate application"

      click_link "Start new or view existing requests"

      expect(page).to have_no_button("Invalidate application")

      click_link "Add new request"

      within("fieldset", text: "Send a validation request") do
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

      expect(page).to have_text("Sent: validation request (description#1)")
      expect(page).to have_text(invalid_planning_application.description)
      expect(page).to have_text("New description")
      expect(page).to have_text(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
      expect(ActionMailer::Base.deliveries.count).to eql(delivered_emails + 1)
    end
  end
end
