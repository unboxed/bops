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

  let!(:consultation) { create(:consultation, end_date: "2023-07-08 16:17:35 +0100", planning_application:) }
  let!(:neighbour) { create(:neighbour, consultation:) }

  before do
    sign_in assessor
    visit planning_application_path(planning_application)
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
    visit planning_application_audits_path(planning_application)
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
    fill_in "Or add a new neighbour address", with: "123 Street"
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
    expect(page).to have_content("123 Street")
    expect(page).to have_content("I think this proposal looks great")
    expect(page).to have_content("Objection")

    # Check audit log
    visit planning_application_audits_path(planning_application)
    within("#audit_#{Audit.last.id}") do
      expect(page).to have_content("Neighbour response uploaded")
      expect(page).to have_content(assessor.name)
      expect(page).to have_content(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
    end

    # Check neighbour is not added to the selected neighbours page
    visit planning_application_consultation_path(planning_application, planning_application.consultation)
    expect(page).not_to have_content("123 Street")
  end

  it "allows planning officer to edit neighbour responses" do
    click_link "View neighbour responses"

    expect(page).to have_content("08/07/2023")
    expect(page).to have_content("No neighbour responses yet")
    expect(page).to have_link("Back", href: planning_application_consultations_path(planning_application))

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
    expect(page).to have_content(" #{neighbour.address}")
    expect(page).to have_content("I think this proposal looks great")

    click_link "Edit"

    fill_in "Name", with: "Sara Neighbour"
    fill_in "Email", with: "sara@email.com"
    fill_in "Address", with: "124 Made up Street"
    fill_in "Day", with: "21"
    fill_in "Month", with: "2"
    fill_in "Year", with: "2023"
    fill_in "Redacted response", with: "I think this proposal looks ****"

    click_button "Update response"

    expect(page).to have_content("Received on 21/02/2023")
    expect(page).to have_content("Sara Neighbour")
    expect(page).to have_content("sara@email.com")
    expect(page).to have_content("124 Made up Street")
    expect(page).to have_content("I think this proposal looks ****")

    expect(page).to have_link("Back", href: planning_application_consultations_path(planning_application, @consultation))

    # Check audit log
    visit planning_application_audits_path(planning_application)
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
end
