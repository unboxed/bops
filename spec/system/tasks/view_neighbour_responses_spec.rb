# frozen_string_literal: true

require "rails_helper"

RSpec.describe "View neighbour responses task", type: :system, js: true do
  include ActionDispatch::TestProcess::FixtureFile

  let(:default_local_authority) { create(:local_authority, :default) }
  let!(:api_user) { create(:api_user, :planx, local_authority: default_local_authority) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }
  let!(:application_type) { create(:application_type, :planning_permission) }

  let!(:planning_application) do
    create(:planning_application, :published, :from_planx_prior_approval,
      application_type:, local_authority: default_local_authority, api_user:)
  end
  let(:task) { planning_application.case_record.find_task_by_slug_path!("consultees-neighbours-and-publicity/neighbours/view-neighbour-responses") }
  let!(:consultation) { planning_application.consultation }
  let!(:neighbour) { create(:neighbour, consultation:) }

  before do
    consultation.update(end_date: "2026-06-10 16:17:35 +0100")

    sign_in assessor
    visit "/planning_applications/#{planning_application.reference}"
    click_link "Consultees, neighbours and publicity"
    within :sidebar do
      click_link "View neighbour responses"
    end
  end

  it "allows planning officer to upload neighbour response who was consulted" do
    expect(task.reload).to be_not_started

    expect(page).to have_content("10 June 2026")
    expect(page).to have_content("No neighbour responses yet")

    click_link "Add neighbour response"

    fill_in "Name", with: "Sarah Neighbour"
    fill_in "Email", with: "sarah@email.com"
    select(neighbour.address.to_s, from: "Select an existing neighbour address")
    fill_in "Day", with: "02"
    fill_in "Month", with: "02"
    fill_in "Year", with: "2026"
    fill_in "Response", with: "I think this proposal looks great and I would like to make a really long comment about how great it is and please let this person build this thing."
    choose "Supportive"

    click_button "Save response"

    expect(page).to have_content("Successfully saved neighbour response")
    expect(page).not_to have_content("No neighbour responses yet")
    expect(page).to have_content "Responses (1)"
    expect(task.reload).to be_in_progress

    click_button "Supportive responses (1)"

    expect(page).to have_content("Sarah Neighbour")
    expect(page).to have_content("sarah@email.com")
    expect(page).to have_content(neighbour.address.to_s)
    expect(page).to have_content("I think this proposal looks great and I would like to make a really long comment about how great...")
    expect(page).to have_content("Supportive")
    expect(page).to have_content("Adjoining neighbour")

    click_link "View more"

    expect(page).to have_content("I think this proposal looks great and I would like to make a really long comment about how great it is and please let this person build this thing.")

    # Check audit log
    visit "/planning_applications/#{planning_application.reference}/audits"
    within("#audit_#{Audit.last.id}") do
      expect(page).to have_content("Neighbour response uploaded")
      expect(page).to have_content(assessor.name)
      expect(page).to have_content(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
    end
  end

  it "allows planning officer to upload neighbour response who was not consulted" do
    expect(page).to have_content("No neighbour responses yet")

    click_link "Add neighbour response"

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
    expect(task.reload).to be_in_progress

    click_button "Objection responses (1)"

    expect(page).to have_content("Received on 21/01/2023")
    expect(page).to have_content("Sarah Neighbour")
    expect(page).to have_content("sarah@email.com")
    expect(page).to have_content("123, Street, AAA111")
    expect(page).to have_content("I think this proposal looks great")
    expect(page).to have_content("Objection")

    # Check audit log
    visit "/planning_applications/#{planning_application.reference}/audits"
    within("#audit_#{Audit.last.id}") do
      expect(page).to have_content("Neighbour response uploaded")
      expect(page).to have_content(assessor.name)
      expect(page).to have_content(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
    end
  end

  it "displays an error when new address format is invalid" do
    click_link "Add neighbour response"

    fill_in "Name", with: "Sarah Neighbour"
    fill_in "Email", with: "sarah@email.com"
    fill_in "Or add a new neighbour address", with: "123 Street"
    fill_in "Day", with: "21"
    fill_in "Month", with: "1"
    fill_in "Year", with: "2023"
    fill_in "Response", with: "I think this proposal looks great"
    choose "An objection"

    click_button "Save response"

    within(".govuk-error-summary") do
      expect(page).to have_content("There is a problem")
      expect(page).to have_content("'123 Street' is invalid")
      expect(page).to have_content("Enter the property name or number, followed by a comma")
      expect(page).to have_content("Enter the street name, followed by a comma")
      expect(page).to have_content("Enter a postcode, like AA11AA")
    end

    expect(NeighbourResponse.count).to eq(0)
  end

  it "allows planning officer to edit neighbour responses" do
    click_link "Add neighbour response"

    fill_in "Name", with: "Sarah Neighbour"
    fill_in "Email", with: "sarah@email.com"
    select(neighbour.address.to_s, from: "Select an existing neighbour address")
    fill_in "Day", with: "21"
    fill_in "Month", with: "1"
    fill_in "Year", with: "2026"
    choose "Supportive"
    fill_in "Response", with: "I think this proposal looks great"

    click_button "Save response"

    click_button "Supportive responses (1)"

    expect(page).to have_content("Received on 21/01/2026")
    expect(page).to have_content("Sarah Neighbour")
    expect(page).to have_content("sarah@email.com")
    expect(page).to have_content(neighbour.address.to_s)
    expect(page).to have_content("I think this proposal looks great")

    click_link "Edit"

    fill_in "Name", with: "James Neighbour"

    click_button "Update response"
    expect(page).to have_content("Successfully updated neighbour response")

    expect(page).to have_content("James Neighbour")
    expect(page).not_to have_content("Sarah Neighbour")

    # Check audit log
    visit "/planning_applications/#{planning_application.reference}/audits"
    within("#audit_#{Audit.last.id}") do
      expect(page).to have_content("Neighbour response edited")
      expect(page).to have_content(assessor.name)
      expect(page).to have_content(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
    end
  end

  context "when redacting a response" do
    let!(:neighbour_response) do
      create(:neighbour_response, :without_redaction, consultation_id: consultation.id, neighbour:, response: "It will be too noisy, I hate my neighbour!")
    end

    before do
      visit current_path
      click_button "Supportive responses (1)"
    end

    it "does not show the redaction field when editing a response" do
      click_link "Edit"

      expect(page).not_to have_field("Redacted comment")
      click_link "Back"
    end

    it "allows planning officer to redact a response" do
      expect(page).not_to have_content("Redacted by")

      click_link "Redact and publish"

      fill_in "Redacted comment", with: "It will be too noisy, [redacted]"
      click_button "Save and publish"

      click_button "Supportive responses (1)"
      expect(page).to have_content("Redacted by: #{assessor.name}")
    end

    it "allows planning officer to save and complete the task" do
      click_button "Save and mark as complete"

      expect(page).to have_content("Successfully saved neighbour response task")
      expect(task.reload).to be_completed
    end
  end
end
