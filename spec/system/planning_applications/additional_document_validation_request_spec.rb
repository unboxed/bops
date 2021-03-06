# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Requesting a new document for a planning application", type: :system do
  let!(:assessor) { create :user, :assessor, local_authority: @default_local_authority }

  let!(:planning_application) do
    create :planning_application, :invalidated, local_authority: @default_local_authority
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

  it "allows for a document creation request to be created and sent to the applicant" do
    click_link "Validate application"
    click_link "Start new or view existing validation requests"
    click_link "Add new request"

    within("fieldset", text: "Send a validation request") do
      choose "Request a new document"
    end

    click_button "Next"

    expect(page).to have_content("Request a new document")

    fill_in "Please specify the new document type:", with: "Backyard plans"
    fill_in "Please specify the reason you have requested this document?", with: "Application is missing a rear view."

    click_button "Send"
    expect(page).to have_content("Document create request successfully sent.")

    click_link "Application"
    click_button "Key application dates"
    click_link "Activity log"

    expect(page).to have_text("Sent: validation request (new document#1)")
    expect(page).to have_text("Document: Backyard plans")
    expect(page).to have_text("Reason: Application is missing a rear view.")
    expect(page).to have_text(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
  end

  it "does not allow for a creation request without a document request reason and type" do
    click_link "Validate application"
    click_link "Start new or view existing validation requests"
    click_link "Add new request"

    within("fieldset", text: "Send a validation request") do
      choose "Request a new document"
    end

    click_button "Next"
    click_button "Send"

    expect(page).to have_content("Please fill in the document request type.")
    expect(page).to have_content("Please fill in the reason for this document request.")

    fill_in "Please specify the reason you have requested this document?", with: "Application is missing a floor plan."
    click_button "Send"
    expect(page).to have_content("Please fill in the document request type.")
    fill_in "Please specify the new document type:", with: "Floor plan"
    click_button "Send"

    expect(page).to have_content("Document create request successfully sent.")
  end

  it "displays the details of the received request in the audit log" do
    create :audit, planning_application_id: planning_application.id, activity_type: "additional_document_validation_request_received", activity_information: 1, audit_comment: "roof_plan.pdf", api_user: api_user

    sign_in assessor
    visit planning_application_path(planning_application)

    click_button "Key application dates"
    click_link "Activity log"

    expect(page).to have_text("Received: request for change (new document#1)")
    expect(page).to have_text("roof_plan.pdf")
    expect(page).to have_text("Applicant / Agent via Api Wizard")
  end
end
