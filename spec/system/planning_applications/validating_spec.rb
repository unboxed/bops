# frozen_string_literal: true

require "rails_helper"

RSpec.shared_examples "validate and invalidate" do
  let!(:second_planning_application) do
    create :planning_application, local_authority: @default_local_authority
  end

  it "can be validated and displays link to notification" do
    delivered_emails = ActionMailer::Base.deliveries.count
    click_link planning_application.reference
    click_link "Validate application"

    fill_in "Day", with: "03"
    fill_in "Month", with: "12"
    fill_in "Year", with: "2021"

    click_button "Validate application"

    expect(page).to have_content("Application is ready for assessment")

    planning_application.reload
    expect(planning_application.status).to eq("in_assessment")
    expect(planning_application.documents_validated_at).to eq(Date.new(2021, 12, 3))

    expect(ActionMailer::Base.deliveries.count).to eq(delivered_emails + 1)

    click_button "Key application dates"
    click_link "Activity log"

    expect(page).to have_text("Application validated")
    expect(page).to have_text(assessor.name)
    expect(page).to have_text(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))

    click_link("Application")
    click_link("Validate application")
    expect(page).to have_link("View notification")

    click_link "View notification"
    expect(page).to have_content(planning_application.reference)
    expect(page).to have_content(planning_application.full_address)
    expect(page).to have_content("Your application is now valid")
    expect(page).to have_content(planning_application.documents_validated_at.strftime("%e %B %Y"))
  end

  it "allows document edit, archive and upload after invalidation" do
    create :description_change_validation_request, planning_application: planning_application, state: "open", created_at: 12.days.ago

    click_link planning_application.reference
    click_button "Documents"
    click_link "Manage documents"
    click_link "Archive"

    fill_in "Why do you want to archive this document?", with: "Scale was wrong"
    click_button "Archive"

    expect(page).to have_text("proposed-floorplan.png has been archived")
  end

  it "displays a validation date of the last closed validation request if any closed validation requests exist" do
    create(:description_change_validation_request,
           planning_application: planning_application,
           proposed_description: "new roof",
           state: "closed",
           updated_at: Time.zone.today - 2.days)

    create(:replacement_document_validation_request,
           planning_application: planning_application,
           state: "closed",
           updated_at: Time.zone.today - 3.days)

    click_link planning_application.reference
    click_link "Validate application"

    expect(page).to have_field("Day", with: description_change_validation_request.updated_at.strftime("%-d"))
    expect(page).to have_field("Month", with: description_change_validation_request.updated_at.strftime("%-m"))
    expect(page).to have_field("Year", with: description_change_validation_request.updated_at.strftime("%Y"))
  end

  it "displays a validation date of when the documents where validated if no closed validation requests exist" do
    visit validate_form_planning_application_path(second_planning_application)

    expect(page).to have_field("Day", with: second_planning_application.documents_validated_at.strftime("%-d"))
    expect(page).to have_field("Month", with: second_planning_application.documents_validated_at.strftime("%-m"))
    expect(page).to have_field("Year", with: second_planning_application.documents_validated_at.strftime("%Y"))
  end

  it "allows for the user to input a validation date manually" do
    visit validate_form_planning_application_path(second_planning_application)

    fill_in "Day", with: "3"
    fill_in "Month", with: "6"
    fill_in "Year", with: "2022"

    click_button "Validate application"

    second_planning_application.reload
    expect(second_planning_application.documents_validated_at.to_s).to eq("2022-06-03")
  end
end

RSpec.describe "Planning Application Assessment", type: :system do
  let!(:assessor) { create :user, :assessor, local_authority: @default_local_authority }

  let!(:planning_application) do
    create :planning_application, :not_started, local_authority: @default_local_authority
  end

  let!(:description_change_validation_request) do
    create :description_change_validation_request, planning_application: planning_application, state: "closed"
  end

  let!(:document) do
    create :document, :with_file, :with_tags, planning_application: planning_application
  end

  before do
    sign_in assessor
    visit root_path
  end

  context "Checking documents from Not Started status" do
    include_examples "validate and invalidate"

    it "can be invalidated and email is sent when there is an open validation request" do
      create :description_change_validation_request, planning_application: planning_application, state: "open", created_at: 12.days.ago

      delivered_emails = ActionMailer::Base.deliveries.count
      click_link planning_application.reference
      click_link "Validate application"

      click_link "Start new or view existing validation requests"

      click_button "Invalidate application"

      expect(page).to have_content("Application has been invalidated")

      planning_application.reload
      expect(planning_application.status).to eq("invalidated")

      expect(ActionMailer::Base.deliveries.count).to eq(delivered_emails + 1)

      click_button "Key application dates"
      click_link "Activity log"

      expect(page).to have_text("Application invalidated")
      expect(page).to have_text(assessor.name)
      expect(page).to have_text(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
    end
  end

  context "Checking documents from Invalidated status" do
    let!(:planning_application) do
      create :planning_application, :invalidated, local_authority: @default_local_authority
    end

    include_examples "validate and invalidate"

    it "shows error if trying to mark as valid when open validation request exists on planning application" do
      create :description_change_validation_request, planning_application: planning_application, state: "open"

      click_link planning_application.reference

      click_link "Validate application"

      expect(page).to have_content("This application has 1 unresolved validation request")

      click_button "Validate application"

      expect(page).to have_content("Planning application cannot be validated if open validation requests exist")
    end
  end

  context "Planning application does not transition when expected inputs are not sent" do
    it "shows error if invalid date is sent" do
      click_link planning_application.reference
      click_link "Validate application"

      fill_in "Day", with: "3"
      fill_in "Month", with: "&&£$£$"
      fill_in "Year", with: "2022"

      click_button "Validate application"

      planning_application.reload
      # This is stopped by HTML 5 validations, which are hard to test the UI for.
      expect(planning_application.status).to eql("not_started")
    end

    it "shows error if date is empty" do
      click_link planning_application.reference
      click_link "Validate application"

      fill_in "Day", with: ""
      fill_in "Month", with: ""
      fill_in "Year", with: ""

      click_button "Validate application"

      planning_application.reload
      expect(planning_application.status).to eql("not_started")
      expect(page).to have_content("Please enter a valid date")
    end

    it "shows error if only part of the date is empty" do
      click_link planning_application.reference
      click_link "Validate application"

      fill_in "Day", with: ""
      fill_in "Month", with: ""
      fill_in "Year", with: "2021"

      click_button "Validate application"

      planning_application.reload
      expect(planning_application.status).to eql("not_started")
      expect(page).to have_content("Please enter a valid date")

      fill_in "Day", with: ""
      fill_in "Month", with: "2"
      fill_in "Year", with: ""

      click_button "Validate application"

      planning_application.reload
      expect(planning_application.status).to eql("not_started")
      expect(page).to have_content("Please enter a valid date")

      fill_in "Day", with: "1"
      fill_in "Month", with: ""
      fill_in "Year", with: ""

      click_button "Validate application"

      planning_application.reload
      expect(planning_application.status).to eql("not_started")
      expect(page).to have_content("Please enter a valid date")
    end

    it "shows edit, upload and archive links for documents" do
      click_link planning_application.reference
      click_button "Documents"
      click_link "Manage documents"

      expect(page).to have_link("Edit")
      expect(page).to have_link("Upload document")
      expect(page).to have_link("Archive")
    end
  end

  context "Planning application is in determined state" do
    let!(:determined_planning_application) do
      create :planning_application, :determined, local_authority: @default_local_authority
    end

    it "does not show validate form" do
      visit planning_application_documents_path(determined_planning_application)

      expect(page).not_to have_content("Validate application")
    end

    it "does not allow new requests when application is determined" do
      visit planning_application_validation_requests_path(determined_planning_application)

      expect(page).not_to have_button("Invalidate application")
      expect(page).not_to have_button("New request")
      expect(page).not_to have_content("Add all required validation requests for this application")
    end
  end

  context "Invalidation with no requests" do
    it "shows correct errors and status when there are no open validation requests" do
      visit planning_application_path(planning_application)
      click_link "Validate application"

      click_link "Start new or view existing validation requests"

      expect(page).to have_content("Add all required validation requests for this application. Once all requests have been added, you can invalidate the application and notify the applicant that the application is invalid and they can see all validation requests")

      click_button "Invalidate application"
      expect(page).to have_content("Please create at least one validation request")
      expect(planning_application.status).to eql("not_started")
    end
  end

  context "Application not started" do
    it "shows text and links when application has not been started" do
      visit planning_application_path(planning_application)
      click_link "Validate application"

      expect(page).to have_content("The application has not yet been marked as valid or invalid")
      expect(page).to have_content("This application has 0 resolved validation requests and 1 unresolved validation request")

      click_link "Start new or view existing validation requests"

      expect(page).to have_content("Add all required validation requests for this application. Once all requests have been added, you can invalidate the application and notify the applicant that the application is invalid and they can see all validation requests")
      expect(page).to have_content("The application has not yet been marked as valid or invalid")
    end
  end

  context "Application invalidated" do
    it "does not show the invalidate button when application is invalid" do
      invalid_planning_application = create :planning_application, :invalidated, local_authority: @default_local_authority

      visit planning_application_path(invalid_planning_application)
      click_link "Validate application"

      expect(page).to have_content("The application is marked as invalid. The applicant was notified on #{invalid_planning_application.invalidated_at.strftime('%e %B %Y')}")
    end
  end
end
