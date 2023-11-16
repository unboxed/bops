# frozen_string_literal: true

require "rails_helper"

RSpec.describe "View neighbour responses", js: true do
  include ActionDispatch::TestProcess::FixtureFile

  let!(:api_user) { create(:api_user, name: "PlanX") }
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }
  let!(:application_type) { create(:application_type, :prior_approval) }

  let!(:planning_application) do
    create(:planning_application, :from_planx_prior_approval,
      application_type:, local_authority: default_local_authority, api_user:)
  end

  let!(:consultation) { planning_application.consultation }
  let!(:neighbour) { create(:neighbour, consultation:) }

  before do
    consultation.update(end_date: "2023-07-08 16:17:35 +0100")

    sign_in assessor
    visit "/planning_applications/#{planning_application.id}"
    click_link "Consultees, neighbours and publicity"
  end

  it "allows planning officer to upload neighbour response who was consulted" do
    click_link "View neighbour responses"

    expect(page).to have_content("08/07/2023")
    expect(page).to have_content("No neighbour responses yet")

    click_link "Add a new neighbour response"

    fill_in "Name", with: "Sarah Neighbour"
    fill_in "Email", with: "sarah@email.com"
    select(neighbour.address.to_s, from: "Select an existing neighbour address")
    fill_in "Day", with: "21"
    fill_in "Month", with: "1"
    fill_in "Year", with: "2023"
    fill_in "Response", with: "I think this proposal looks great and I would like to make a really long comment about how great it is and please let this person build this thing."
    choose "Supportive"

    click_button "Save response"

    expect(page).to have_content("Neighbour response successfully created.")
    expect(page).not_to have_content("No neighbour responses yet")

    click_button "Supportive responses (1)"

    expect(page).to have_content("Received on 21/01/2023")
    expect(page).to have_content("Sarah Neighbour")
    expect(page).to have_content("sarah@email.com")
    expect(page).to have_content(neighbour.address.to_s)
    expect(page).to have_content("I think this proposal looks great and I would like to make a really long comment about how great...")
    expect(page).to have_content("Supportive")
    expect(page).to have_content("Adjoining neighbour")

    click_link "View more"

    expect(page).to have_content("I think this proposal looks great and I would like to make a really long comment about how great it is and please let this person build this thing.")

    # Check audit log
    visit "/planning_applications/#{planning_application.id}/audits"
    within("#audit_#{Audit.last.id}") do
      expect(page).to have_content("Neighbour response uploaded")
      expect(page).to have_content(assessor.name)
      expect(page).to have_content(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
    end
  end

  it "allows planning officer to upload neighbour response who was not consulted" do
    click_link "View neighbour responses"

    expect(page).to have_content("08/07/2023")
    expect(page).to have_content("No neighbour responses yet")

    click_link "Add a new neighbour response"

    fill_in "Name", with: "Sarah Neighbour"
    fill_in "Email", with: "sarah@email.com"
    fill_in "Or add a new neighbour address", with: "123, Street, AAA111"
    fill_in "Day", with: "21"
    fill_in "Month", with: "1"
    fill_in "Year", with: "2023"
    fill_in "Response", with: "I think this proposal looks great"
    choose "An objection"

    click_button "Save response"

    expect(page).not_to have_content("No neighbour responses yet")

    click_button "Objection responses (1)"

    expect(page).to have_content("Received on 21/01/2023")
    expect(page).to have_content("Sarah Neighbour")
    expect(page).to have_content("sarah@email.com")
    expect(page).to have_content("123, Street, AAA111")
    expect(page).to have_content("I think this proposal looks great")
    expect(page).to have_content("Objection")

    # Check audit log
    visit "/planning_applications/#{planning_application.id}/audits"
    within("#audit_#{Audit.last.id}") do
      expect(page).to have_content("Neighbour response uploaded")
      expect(page).to have_content(assessor.name)
      expect(page).to have_content(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
    end

    # Check neighbour is not added to the selected neighbours page
    visit "/planning_applications/#{planning_application.id}/consultation"
    expect(page).not_to have_content("123 Street, AAA111")
  end

  it "allows planning officer to upload neighbour response with redaction" do
    click_link "View neighbour responses"
    click_link "Add a new neighbour response"

    fill_in "Name", with: "Matt Neighbour"
    fill_in "Email", with: "matt@email.com"
    select(neighbour.address.to_s, from: "Select an existing neighbour address")
    fill_in "Day", with: "21"
    fill_in "Month", with: "1"
    fill_in "Year", with: "2023"
    fill_in "Response", with: "This proposal will block my sunlight and I hate my neighbour."
    fill_in "Redacted response", with: "This proposal will block my sunlight [redacted]."
    choose "An objection"

    click_button "Save response"
    click_button "Objection responses (1)"

    within(".neighbour-response-content") do
      expect(page).to have_content("Received on 21/01/2023")
      expect(page).to have_content("Matt Neighbour")
      expect(page).to have_content("matt@email.com")
      expect(page).to have_content(neighbour.address.to_s)
      expect(page).to have_content("This proposal will block my sunlight [redacted].")
      expect(page).to have_content("Objection")
      expect(page).to have_content("Adjoining neighbour")
    end

    expect(page).to have_link("Redact and publish")
    expect(page).to have_content("Redacted by: #{assessor.name}")
  end

  it "displays an error message when address is invalid" do
    click_link "View neighbour responses"
    click_link "Add a new neighbour response"

    fill_in "Name", with: "Sarah Neighbour"
    fill_in "Email", with: "sarah@email.com"
    fill_in "Or add a new neighbour address", with: "123 Street"
    fill_in "Day", with: "21"
    fill_in "Month", with: "1"
    fill_in "Year", with: "2023"
    fill_in "Response", with: "I think this proposal looks great"
    choose "An objection"

    click_button "Save response"

    within(".flash.govuk-error-summary") do
      expect(page).to have_content("There is a problem")
      expect(page).to have_content("'123 Street' is invalid")
      expect(page).to have_content("Enter the property name or number, followed by a comma")
      expect(page).to have_content("Enter the street name, followed by a comma")
      expect(page).to have_content("Enter a postcode, like AA11AA")
    end

    expect(NeighbourResponse.count).to eq(0)
    expect(Neighbour.count).to eq(1)
  end

  it "allows planning officer to edit neighbour responses" do
    click_link "View neighbour responses"

    expect(page).to have_content("08/07/2023")
    expect(page).to have_content("No neighbour responses yet")
    expect(page).to have_link("Back", href: planning_application_consultation_path(planning_application))

    click_link "Add a new neighbour response"

    fill_in "Name", with: "Sarah Neighbour"
    fill_in "Email", with: "sarah@email.com"
    select(neighbour.address.to_s, from: "Select an existing neighbour address")
    fill_in "Day", with: "21"
    fill_in "Month", with: "1"
    fill_in "Year", with: "2023"
    choose "Supportive"
    fill_in "Response", with: "I think this proposal looks great"

    click_button "Save response"

    click_button "Supportive responses (1)"

    expect(page).to have_content("Received on 21/01/2023")
    expect(page).to have_content("Sarah Neighbour")
    expect(page).to have_content("sarah@email.com")
    expect(page).to have_content(neighbour.address.to_s)
    expect(page).to have_content("I think this proposal looks great")

    click_link "Edit"

    fill_in "Name", with: "Sara Neighbour"
    fill_in "Email", with: "sara@email.com"
    fill_in "Address", with: "124, Made up"
    fill_in "Day", with: "21"
    fill_in "Month", with: "2"
    fill_in "Year", with: "2023"
    fill_in "Redacted response", with: "I think this proposal looks ****"

    click_button "Update response"

    within(".flash.govuk-error-summary") do
      expect(page).to have_content("There is a problem")
      expect(page).to have_content("'124, Made up' is invalid")
      expect(page).to have_content("Enter the property name or number, followed by a comma")
      expect(page).to have_content("Enter the street name, followed by a comma")
      expect(page).to have_content("Enter a postcode, like AA11AA")
    end

    fill_in "Address", with: "124, Made up street, AAA111"
    click_button "Update response"

    expect(page).to have_content("Neighbour response successfully updated.")

    expect(page).to have_content("Received on 21/02/2023")
    expect(page).to have_content("Sara Neighbour")
    expect(page).to have_content("sara@email.com")
    expect(page).to have_content("124, Made up street, AAA111")
    expect(page).to have_content("I think this proposal looks ****")

    expect(page).to have_link("Back", href: planning_application_consultation_path(planning_application))

    # Check audit log
    visit "/planning_applications/#{planning_application.id}/audits"
    within("#audit_#{Audit.last.id}") do
      expect(page).to have_content("Neighbour response edited")
      expect(page).to have_content(assessor.name)
      expect(page).to have_content(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
    end
  end

  it "shows documents associated with responses" do
    click_link "View neighbour responses"

    click_link "Add a new neighbour response"

    fill_in "Name", with: "Sarah Neighbour"
    fill_in "Email", with: "sarah@email.com"
    select(neighbour.address.to_s, from: "Select an existing neighbour address")
    fill_in "Day", with: "21"
    fill_in "Month", with: "1"
    fill_in "Year", with: "2023"
    fill_in "Response", with: "I think this proposal looks great"
    choose "Supportive"
    attach_file("Upload documents", "spec/fixtures/images/proposed-floorplan.png")

    click_button "Save response"

    click_button "Supportive responses (1)"

    expect(page).to have_content("Received on 21/01/2023")
    expect(page).to have_content("Sarah Neighbour")
    expect(page).to have_content("sarah@email.com")
    expect(page).to have_content(neighbour.address.to_s)
    expect(page).to have_content("I think this proposal looks great")
    expect(page).to have_content("proposed-floorplan")
  end

  it "shows error messages" do
    click_link "View neighbour responses"

    click_link "Add a new neighbour response"

    click_button "Save response"

    expect(page).to have_content("There is a problem")
    expect(page).to have_content("Neighbour must exist")
    expect(page).to have_content("Name can't be blank")
    expect(page).to have_content("Response can't be blank")
    expect(page).to have_content("Summary tag can't be blank")
    expect(page).to have_content("Received at can't be blank")
  end

  context "when there is no end date yet but there are responses" do
    let!(:response) { create(:neighbour_response, neighbour:) }

    before do
      consultation.update(end_date: nil)
    end

    it "is marked as not started" do
      visit "/planning_applications/#{planning_application.id}"
      click_link "Consultees, neighbours and publicity"
      expect(page).to have_content("View neighbour responses Not started")
    end
  end

  context "when redacting a response" do
    let!(:response) { create(:neighbour_response, :objection, :without_redaction, neighbour:, response: "It will be too noisy, I hate my neighbour!") }

    it "shows the relevant content for redacting a comment" do
      click_link "View neighbour responses"
      click_button "Objection responses (1)"
      click_link "Redact and publish"

      within("#planning-application-details") do
        expect(page).to have_content("Redact comment")
        expect(page).to have_content(planning_application.reference)
        expect(page).to have_content(planning_application.full_address)
        expect(page).to have_content(planning_application.description)
      end
      within(".govuk-breadcrumbs__list") do
        expect(page).to have_content("Redact comment")
      end

      expect(page).to have_content("Comment submitted by")
      expect(page).to have_content(response.name.to_s)
      expect(page).to have_content(response.email.to_s)
      expect(page).to have_content(neighbour.address.to_s)
      expect(page).to have_content("It will be too noisy, I hate my neighbour!")

      within(".govuk-details") do
        within(".govuk-details__summary") do
          expect(page).to have_content("What you need to redact")
        end

        within(".govuk-details__text") do
          expect(page).to have_content("You need to redact any:")
          expect(page).to have_content("Personal data")
          expect(page).to have_content("Names")
          expect(page).to have_content("Third party address")
          expect(page).to have_content("Contact information")
          expect(page).to have_content("Personal details")
          expect(page).to have_content("Special category data")
        end
      end

      expect(page).to have_link "Back", href: planning_application_consultation_neighbour_responses_path(planning_application)
    end

    it "allows officer to review redaction guidelines and redact a neighbour response" do
      click_link "View neighbour responses"
      click_button "Objection responses (1)"
      expect(page).not_to have_content("Redacted by")

      click_link "Redact and publish"
      expect(page).to have_content("This is the full text of the comment before redaction.")
      expect(page).to have_selector("#neighbour-response-response-field[readonly]")

      expect(page).to have_content("Replace text you want to redact with [redacted] then save to publish the comment.")
      fill_in "Redacted comment", with: "It will be too noisy, [redaction]"

      click_button "Save and publish"
      expect(page).to have_content("Neighbour response was successully updated.")

      click_button "Objection responses (1)"
      expect(page).to have_content("Redacted by: #{assessor.name}")

      click_link "Redact and publish"
      # Check I can reset redacted comment to the original comment
      expect(find_by_id("neighbour_response_redacted_response").value).to eq("It will be too noisy, [redaction]")
      click_button "Reset comment"
      expect(find_by_id("neighbour_response_redacted_response").value).to eq("It will be too noisy, I hate my neighbour!")
    end
  end
end
