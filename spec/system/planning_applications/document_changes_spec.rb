# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Requesting document changes to a planning application", type: :system do
  let!(:assessor) { create :user, :assessor, local_authority: @default_local_authority }

  let!(:planning_application) do
    create :planning_application, :invalidated, local_authority: @default_local_authority
  end

  let!(:invalid_document) do
    create :document, :with_file,
           validated: false,
           invalidated_document_reason: "Not readable",
           planning_application: planning_application
  end

  let!(:valid_document) { create :document }

  before do
    travel_to Time.zone.local(2021, 1, 1)
    sign_in assessor
    visit planning_application_path(planning_application)
  end

  after do
    travel_back
  end

  it "allows for a document change request to be created for invalid documents only" do
    valid_document.file.attach(
      io: File.open(Rails.root.join("spec/fixtures/images/existing-roofplan.pdf")),
      filename: "wowee-florzoplan.png",
      content_type: "image/png",
    )

    click_link "Validate application"
    click_link "Start new or view existing requests"
    click_link "Add new request"

    within("fieldset", text: "Send a change request") do
      choose "Request replacement documents"
    end

    click_button "Next"

    expect(page).to have_content("Request replacement documents")
    expect(page).to have_content("The following documents have been marked as invalid.")
    expect(page).to have_content(invalid_document.name.to_s)
    expect(page).not_to have_content(valid_document.name.to_s)

    click_button "Send"
    expect(page).to have_content("Document change request successfully sent.")

    click_link "Application"
    click_button "Key application dates"
    click_link "Activity log"

    expect(page).to have_text("Sent: request for change (replacement document#1)")
    expect(page).to have_text(invalid_document.name.to_s)
    expect(page).to have_text("Invalid reason: Not readable")
    expect(page).to have_text(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
  end

  it "does not display invalid document as an option to create a change request if that document already has an associated change request" do
    create :document_change_request, planning_application: planning_application, old_document: invalid_document, state: "open", created_at: 12.days.ago

    click_link "Validate application"
    click_link "Start new or view existing requests"
    click_link "Add new request"

    within("fieldset", text: "Send a change request") do
      choose "Request replacement documents"
    end

    click_button "Next"
    expect(page).not_to have_content(invalid_document.name.to_s)
  end
end
