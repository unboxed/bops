# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Requesting a new document for a planning application", type: :system do
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

  it "allows for a document creation request to be created and sent to the applicant" do
    click_link "Validate application"
    click_link "Start new or view existing requests"
    click_link "Add new request"

    within("fieldset", text: "Send a change request") do
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

    expect(page).to have_text("Sent: request for change (new document#1)")
    expect(page).to have_text("Document: Backyard plans")
    expect(page).to have_text("Reason: Application is missing a rear view.")
    expect(page).to have_text(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
  end

  it "does not allow for a creation request without a document request reason and type" do
    click_link "Validate application"
    click_link "Start new or view existing requests"
    click_link "Add new request"

    within("fieldset", text: "Send a change request") do
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
end
