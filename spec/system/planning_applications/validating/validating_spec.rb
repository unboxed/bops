# frozen_string_literal: true

require "rails_helper"

RSpec.shared_examples "validate and invalidate" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:second_planning_application) do
    create(:planning_application, :not_started, local_authority: default_local_authority)
  end

  it "can be validated and displays link to notification" do
    delivered_emails = ActionMailer::Base.deliveries.count

    within(selected_govuk_tab) do
      click_link(planning_application.reference)
    end

    click_link "Check and validate"
    click_link "Start now"
    click_link "Send validation decision"
    click_link "Mark the application as valid"

    expect(page).to have_content("Valid from")
    fill_in "Day", with: "03"
    fill_in "Month", with: "12"
    fill_in "Year", with: "2021"

    check "Publish application on BoPS applicants?"

    click_button "Mark the application as valid"

    expect(page).to have_content("Application is ready for assessment")
    expect(page).to have_content("Application is public on BoPS applicants")

    planning_application.reload
    expect(planning_application.status).to eq("in_assessment")
    expect(planning_application.validated_at).to eq(Date.new(2021, 12, 3))

    expect(ActionMailer::Base.deliveries.count).to eq(delivered_emails + 2)

    click_link("Application")
    click_link("Check and validate")
    expect(page).to have_link("View notification")

    click_link "View notification"
    expect(page).to have_content(planning_application.reference)
    expect(page).to have_content(planning_application.full_address)
    expect(page).to have_content("Your application is now valid")
    expect(page).to have_content(planning_application.validated_at)
  end

  it "allows document edit, archive and upload after invalidation" do
    create(:additional_document_validation_request, planning_application:, state: "open",
                                                    created_at: 12.days.ago)

    within(selected_govuk_tab) do
      click_link(planning_application.reference)
    end

    click_button "Documents"
    click_link "Manage documents"
    click_link "Archive"

    fill_in "Why do you want to archive this document?", with: "Scale was wrong"
    click_button "Archive"

    expect(page).to have_text("proposed-floorplan.png has been archived")
  end

  it "displays a validation date of the last closed validation request if any closed validation requests exist" do
    create(:additional_document_validation_request,
           planning_application:,
           state: "closed",
           updated_at: Time.zone.today - 2.days)

    create(:replacement_document_validation_request,
           planning_application:,
           state: "closed",
           updated_at: Time.zone.today - 3.days)

    within(selected_govuk_tab) do
      click_link(planning_application.reference)
    end

    click_link "Check and validate"

    expect(page).to have_field("Day", with: additional_document_validation_request.updated_at.strftime("%-d"))
    expect(page).to have_field("Month", with: additional_document_validation_request.updated_at.strftime("%-m"))
    expect(page).to have_field("Year", with: additional_document_validation_request.updated_at.strftime("%Y"))
  end

  it "displays a validation date of when the documents where validated if no closed validation requests exist" do
    visit validate_form_planning_application_path(second_planning_application)

    expect(page).to have_field("Day", with: second_planning_application.validated_at.strftime("%-d"))
    expect(page).to have_field("Month", with: second_planning_application.validated_at.strftime("%-m"))
    expect(page).to have_field("Year", with: second_planning_application.validated_at.strftime("%Y"))
  end

  it "allows for the user to input a validation date manually" do
    visit validate_form_planning_application_path(second_planning_application)
    click_link "Mark the application as valid"
    fill_in "Day", with: "3"
    fill_in "Month", with: "6"
    fill_in "Year", with: "2022"

    click_button "Mark the application as valid"

    second_planning_application.reload
    expect(second_planning_application.validated_at.to_s).to eq("2022-06-03")
  end
end

RSpec.describe "Planning Application Assessment" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application, :not_started, local_authority: default_local_authority)
  end

  let!(:additional_document_validation_request) do
    create(:additional_document_validation_request, planning_application:, state: "closed")
  end

  let!(:document) do
    create(:document, :with_file, :with_tags, planning_application:)
  end

  let!(:new_planning_application) { create(:planning_application, :not_started, local_authority: default_local_authority) }

  before do
    stub_planx_api_response_for("POLYGON ((-0.054597 51.537331, -0.054588 51.537287, -0.054453 51.537313, -0.054597 51.537331))").to_return(
      status: 200, body: "{}"
    )

    sign_in assessor
    visit root_path
  end

  context "when planning application has no boundary geojson" do
    let(:application) do
      create(
        :planning_application,
        :not_started,
        local_authority: default_local_authority,
        boundary_geojson: nil
      )
    end

    let(:boundary_geojson) do
      {
        type: "Feature",
        properties: {},
        geometry: {
          type: "Polygon",
          coordinates: [
            [
              [-0.054597, 51.537331],
              [-0.054588, 51.537287],
              [-0.054453, 51.537313],
              [-0.054597, 51.537331]
            ]
          ]
        }
      }.to_json
    end

    it "blocks validation until boundary geojson has been added" do
      visit(confirm_validation_planning_application_path(application))
      click_button("Mark the application as valid")

      expect(page).to have_content(
        "This application does not have a digital sitemap and cannot be validated. Please create a digital site map before validating this application."
      )

      click_link("create a digital site map")

      expect(page).to have_content("Draw a digital red line boundary")

      execute_script(
        "document.getElementById(
          'planning_application_boundary_geojson'
        ).setAttribute(
          'value',
          '#{boundary_geojson}'
        )"
      )

      click_button("Save")
      click_link("Send validation decision")
      click_link("Mark the application as valid")
      click_button("Mark the application as valid")

      expect(page).to have_content(
        "Application is ready for assessment and an email notification has been sent."
      )
    end
  end

  context "when checking documents from Not Started status" do
    it "can be invalidated and email is sent when there is an open validation request" do
      create(:additional_document_validation_request, planning_application:, state: "pending",
                                                      created_at: 12.days.ago)

      delivered_emails = ActionMailer::Base.deliveries.count

      within(selected_govuk_tab) do
        click_link(planning_application.reference)
      end

      click_link "Check and validate"
      click_link "Send validation decision"
      click_button "Mark the application as invalid"

      expect(page).to have_content("Application has been invalidated")

      planning_application.reload
      expect(planning_application.status).to eq("invalidated")

      perform_enqueued_jobs
      expect(ActionMailer::Base.deliveries.count).to eq(delivered_emails + 1)
    end
  end

  context "when checking documents from Invalidated status" do
    let!(:planning_application) do
      create(:planning_application, :invalidated, local_authority: default_local_authority)
    end

    it "shows error if trying to mark as valid when open validation request exists on planning application" do
      create(:additional_document_validation_request, planning_application:, state: "open")

      within(selected_govuk_tab) do
        click_link(planning_application.reference)
      end

      click_link "Check and validate"
      click_link "Send validation decision"

      expect(page).to have_content("This application has 1 unresolved validation request and 1 resolved validation request")

      click_link "Mark the application as valid"
      click_button "Mark the application as valid"

      expect(page).to have_content("Planning application cannot be validated if open validation requests exist")
    end
  end

  context "when planning application does not transition when expected inputs are not sent" do
    it "shows an error when invalid documents are present" do
      create(:document, :with_file,
             planning_application:,
             validated: false, invalidated_document_reason: "Missing a lazy Suzan")

      within(selected_govuk_tab) do
        click_link(planning_application.reference)
      end

      click_link "Check and validate"
      click_link "Send validation decision"

      expect(page).to have_content("You have marked items as invalid, so you cannot validate this application.")
      expect(page).to have_content("If you mark the application as invalid then the applicant or agent will be sent an invalid notification. This notification will contain a link to allow the applicant or agent to view all validation requests and to accept and reject requests.")

      planning_application.reload
      expect(planning_application.status).to eql("not_started")
    end

    it "shows error if invalid date is sent" do
      within(selected_govuk_tab) do
        click_link(new_planning_application.reference)
      end

      click_link "Check and validate"
      click_link "Send validation decision"
      click_link "Mark the application as valid"

      fill_in "Day", with: "3"
      fill_in "Month", with: "&&£$£$"
      fill_in "Year", with: "2022"

      click_button "Mark the application as valid"

      new_planning_application.reload
      expect(new_planning_application.status).to eql("not_started")
      expect(page).to have_content("Please enter a valid date")
    end

    it "shows error if date is empty" do
      within(selected_govuk_tab) do
        click_link(new_planning_application.reference)
      end

      click_link "Check and validate"
      click_link "Send validation decision"
      click_link "Mark the application as valid"

      fill_in "Day", with: ""
      fill_in "Month", with: ""
      fill_in "Year", with: ""

      click_button "Mark the application as valid"

      new_planning_application.reload
      expect(new_planning_application.status).to eql("not_started")
      expect(page).to have_content("Please enter a valid date")
    end

    it "shows error if only part of the date is empty" do
      within(selected_govuk_tab) do
        click_link(new_planning_application.reference)
      end

      click_link "Check and validate"
      click_link "Send validation decision"
      click_link "Mark the application as valid"

      fill_in "Day", with: ""
      fill_in "Month", with: ""
      fill_in "Year", with: "2021"

      click_button "Mark the application as valid"

      new_planning_application.reload
      expect(new_planning_application.status).to eql("not_started")
      expect(page).to have_content("Please enter a valid date")

      fill_in "Day", with: ""
      fill_in "Month", with: "2"
      fill_in "Year", with: ""

      click_button "Mark the application as valid"

      new_planning_application.reload
      expect(new_planning_application.status).to eql("not_started")
      expect(page).to have_content("Please enter a valid date")

      fill_in "Day", with: "1"
      fill_in "Month", with: ""
      fill_in "Year", with: ""

      click_button "Mark the application as valid"

      new_planning_application.reload
      expect(new_planning_application.status).to eql("not_started")
      expect(page).to have_content("Please enter a valid date")
    end

    it "shows edit, upload and archive links for documents" do
      within(selected_govuk_tab) do
        click_link(planning_application.reference)
      end

      click_link("Check and validate")
      click_button "Documents"
      click_link "Manage documents"

      expect(page).to have_link("Edit")
      expect(page).to have_link("Upload document")
      expect(page).to have_link("Archive")
    end
  end

  context "when planning application is in determined state" do
    let!(:determined_planning_application) do
      create(:planning_application, :determined, local_authority: default_local_authority)
    end

    it "does not show validate form" do
      visit planning_application_documents_path(determined_planning_application)

      expect(page).not_to have_content("Check and validate")
    end

    it "does not allow new requests when application is determined" do
      visit planning_application_validation_requests_path(determined_planning_application)

      expect(page).not_to have_button("Mark the application as invalid")
      expect(page).not_to have_button("New request")
      expect(page).not_to have_content("Add all required validation requests for this application")
    end
  end

  context "with invalidation with no requests" do
    it "shows correct errors and status when there are no open validation requests" do
      visit planning_application_path(new_planning_application)
      click_link "Check and validate"
      click_link "Review validation requests"

      expect(planning_application.status).to eql("not_started")
    end
  end

  context "when application not started" do
    it "shows text and links when application has not been started" do
      visit planning_application_path(planning_application)
      click_link "Check and validate"
      click_link "Review validation requests"

      expect(page).to have_content("The following requests will be sent when the application is invalidated.")
      expect(page).to have_content("The application has not been marked as valid or invalid yet.")
      expect(page).to have_content("When all parts of the application have been checked and are correct, mark the application as valid.")
    end
  end

  context "when application invalidated" do
    it "does not show the invalidate button when application is invalid" do
      invalid_planning_application = create(:planning_application, :invalidated,
                                            local_authority: default_local_authority)

      visit planning_application_path(invalid_planning_application)
      click_link "Check and validate"
      click_link "Send validation decision"

      expect(page).to have_content("The application is marked as invalid. The applicant was notified on #{invalid_planning_application.invalidated_at}")
    end
  end

  context "when application validated" do
    before do
      planning_application = create(:planning_application, :in_assessment, local_authority: default_local_authority)

      visit planning_application_path(planning_application)
    end

    it "does not allow you to add requests if application has been validated" do
      click_link "Check and validate"
      click_link "Send validation decision"
      expect(page).to have_content("The application is marked as valid and cannot be marked as invalid.")

      click_link "Back"
      click_link "Review validation requests"
      expect(page).not_to have_link("Add new request")
    end
  end
end
