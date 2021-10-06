# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Auditing changes to a planning application", type: :system do
  let!(:assessor) { create :user, :assessor, local_authority: @default_local_authority }

  let!(:planning_application) do
    create :planning_application, :invalidated, local_authority: @default_local_authority
  end

  let!(:api_user) { create :api_user, name: "Api Wizard" }

  let!(:second_planning_application) do
    create :planning_application,
           :not_started,
           local_authority: @default_local_authority,
           user: assessor,
           description: "Back shack",
           address_1: "1 golden street",
           address_2: "Southwark"
  end

  before do
    create :audit, planning_application_id: planning_application.id,
                   activity_type: "red_line_boundary_change_validation_request_received", activity_information: 1, audit_comment: { response: "rejected", reason: "The boundary was too small" }.to_json, api_user: api_user
    create :audit, planning_application_id: planning_application.id,
                   activity_type: "other_change_validation_request_received", activity_information: 1, audit_comment: { response: "I have sent the fee" }.to_json, api_user: api_user
    create :audit, planning_application_id: planning_application.id,
                   activity_type: "replacement_document_validation_request_received", activity_information: 1, audit_comment: "floor_plan.pdf", api_user: api_user

    sign_in assessor
    visit planning_application_path(planning_application)
    click_button "Key application dates"
    click_link "Activity log"
  end

  it "displays details of other change validation request in the audit log" do
    expect(page).to have_text("Received: request for change (other validation#1)")
    expect(page).to have_text("I have sent the fee")
    expect(page).to have_text("Applicant / Agent via Api Wizard")
  end

  it "displays the details of a red line boundary request in the audit log" do
    expect(page).to have_text("Received: request for change (red line boundary#1)")
    expect(page).to have_text("The boundary was too small")
    expect(page).to have_text("rejected")
    expect(page).to have_text("Applicant / Agent via Api Wizard")
  end

  it "displays the details of replacement boundary requests in the audit log" do
    expect(page).to have_text("Received: request for change (replacement document#1)")
    expect(page).to have_text("floor_plan.pdf")
    expect(page).to have_text("Applicant / Agent via Api Wizard")
  end

  it "creates an audit entry for every edit and update actions" do
    visit planning_application_path(second_planning_application)
    click_button "Application information"
    click_link "Edit details"

    fill_in "Description", with: "doing more than great things, doing wonderful things."
    fill_in "Day", with: "3"
    fill_in "Month", with: "10"
    fill_in "Year", with: "2021"
    fill_in "Address 1", with: "2 Streatham High Road"
    fill_in "Address 2", with: "Streatham"
    fill_in "Town", with: "Crystal Palace"
    fill_in "County", with: "London"
    fill_in "Postcode", with: "SW16 1DB"
    fill_in "UPRN", with: "294884040"
    within "form", text: "Has the work been started?" do
      choose "Yes"
    end
    within ".applicant-information" do
      fill_in "First name", with: "Pearly"
      fill_in "Last name", with: "Poorly"
      fill_in "Email address", with: "pearly@poorly.com"
      fill_in "UK telephone number", with: "0777773949494312"
    end
    within ".agent-information" do
      fill_in "First name", with: "Agentina"
      fill_in "Last name", with: "Agentino"
      fill_in "Email address", with: "agentina@agentino.com"
      fill_in "UK telephone number", with: "923838484492939"
    end

    click_button "Save"
    click_button "Key application dates"
    click_link "Activity log"

    expect(page).to have_text("Description updated")
    expect(page).to have_text("Changed from: Back shack")
    expect(page).to have_text("Changed to: doing more than great things, doing wonderful things.")

    expect(page).to have_text("Address 1 updated")
    expect(page).to have_text("Changed from: 1 golden street")
    expect(page).to have_text("Changed to: 2 Streatham High Road")

    expect(page).to have_text("Address 2 updated")
    expect(page).to have_text("Changed from: Southwark")
    expect(page).to have_text("Changed to: Streatham")

    expect(page).to have_text("Applicant first name updated")
    expect(page).to have_text("Applicant last name updated")
    expect(page).to have_text("Applicant phone updated")
    expect(page).to have_text("Applicant email updated")
    expect(page).to have_text("Agent first name updated")
    expect(page).to have_text("Agent last name updated")
    expect(page).to have_text("Agent phone updated")
    expect(page).to have_text("Agent email updated")
    expect(page).to have_text("County updated")
    expect(page).to have_text("Postcode updated")
    expect(page).to have_text("Town updated")
    expect(page).to have_text("Work status updated")
    expect(page).to have_text("Payment reference updated")
  end
end
