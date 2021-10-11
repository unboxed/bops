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

  let!(:api_user) { create :api_user, name: "Api Wizard" }

  before do
    travel_to Time.zone.local(2021, 1, 1)
    sign_in assessor
    visit planning_application_path(planning_application)
  end

  it "allows for a document validation request to be created for invalid documents only" do
    delivered_emails = ActionMailer::Base.deliveries.count
    valid_document.file.attach(
      io: File.open(Rails.root.join("spec/fixtures/images/existing-roofplan.pdf")),
      filename: "wowee-florzoplan.png",
      content_type: "image/png"
    )

    click_link "Validate application"
    click_link "Start new or view existing requests"
    click_link "Add new request"

    within("fieldset", text: "Send a validation request") do
      choose "Request replacement documents"
    end

    click_button "Next"

    expect(page).to have_content("Request replacement documents")
    expect(page).to have_content("The following documents have been marked as invalid.")
    expect(page).to have_content(invalid_document.name.to_s)
    expect(page).not_to have_content(valid_document.name.to_s)

    click_button "Send"
    expect(page).to have_content("Replacement document validation request successfully created.")

    click_link "Application"
    click_button "Key application dates"
    click_link "Activity log"

    expect(page).to have_text("Sent: validation request (replacement document#1)")
    expect(page).to have_text(invalid_document.name.to_s)
    expect(page).to have_text("Invalid reason: Not readable")
    expect(page).to have_text(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
    expect(ActionMailer::Base.deliveries.count).to eql(delivered_emails + 1)
  end

  it "does not display invalid document as an option to create a validation request if that document already has an associated validation request" do
    create :replacement_document_validation_request, planning_application: planning_application,
                                                     old_document: invalid_document, state: "open", created_at: 12.days.ago

    click_link "Validate application"
    click_link "Start new or view existing requests"
    click_link "Add new request"

    within("fieldset", text: "Send a validation request") do
      choose "Request replacement documents"
    end

    click_button "Next"
    expect(page).not_to have_content(invalid_document.name.to_s)
  end

  context "Invalidation updates replacement document validation request" do
    it "updates the notified_at date of an open request when application is invalidated" do
      new_planning_application = create :planning_application, :not_started, local_authority: @default_local_authority
      request = create :replacement_document_validation_request, planning_application: new_planning_application,
                                                                 state: "pending", created_at: 12.days.ago

      visit planning_application_path(new_planning_application)
      click_link "Validate application"

      click_link "Request validation changes"
      expect(request.notified_at).to be_nil

      click_button "Invalidate application"

      expect(page).to have_content("Application has been invalidated")

      new_planning_application.reload
      expect(new_planning_application.status).to eq("invalidated")

      request.reload
      expect(request.notified_at).to be_a Date
    end
  end
end
