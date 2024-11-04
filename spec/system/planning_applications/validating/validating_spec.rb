# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning Application Assessment", type: :system do
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

  let(:govuk_tab_all) { find("div[class='govuk-tabs__panel']#all") }

  before do
    stub_planx_api_response_for("POLYGON ((-0.054597 51.537331, -0.054588 51.537287, -0.054453 51.537313, -0.054597 51.537331))").to_return(
      status: 200, body: "{}"
    )

    sign_in assessor
    visit "/"
  end

  context "when planning application does not transition when expected inputs are not sent" do
    it "shows an error when invalid documents are present" do
      request = create(:replacement_document_validation_request, state: :pending, planning_application:)
      create(:document, :with_file,
        planning_application:,
        validated: false, invalidated_document_reason: "Missing a lazy Suzan",
        owner: request)

      within(govuk_tab_all) do
        click_link(planning_application.reference)
      end

      click_link "Check and validate"
      click_link "Send validation decision"

      expect(page).to have_content("You have marked items as invalid, so you cannot validate this application.")
      expect(page).to have_content("If you mark the application as invalid then the applicant or agent will be sent an invalid notification. This notification will contain a link to allow the applicant or agent to view all validation requests and to accept and reject requests.")

      planning_application.reload
      expect(planning_application.status).to eql("not_started")
    end

    it "shows edit, upload and archive links for documents" do
      within(govuk_tab_all) do
        click_link(planning_application.reference)
      end

      click_button "Documents"
      click_link "Manage documents"

      expect(page).to have_link("Edit")
      expect(page).to have_link("Upload document")
      expect(page).to have_link("Archive")
    end
  end

  context "when application not started" do
    it "shows text and links when application has not been started" do
      visit "/planning_applications/#{planning_application.reference}"
      click_link "Check and validate"
      click_link "Review validation requests"

      expect(page).to have_content("The following requests will be sent when the application is invalidated.")
      expect(page).to have_content("The application has not been marked as valid or invalid yet.")
      expect(page).to have_content("When all parts of the application have been checked and are correct, mark the application as valid.")
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

      it "blocks validation until boundary geojson has been added", :capybara do
        visit "/planning_applications/#{application.id}/confirm_validation"
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

        click_button("Save and mark as complete")
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

        within(govuk_tab_all) do
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

    context "when a description change request has been sent" do
      it "allows validation of the planning application" do
        planning_application = create(:planning_application, :with_boundary_geojson, :not_started, local_authority: default_local_authority)
        create(:description_change_validation_request, planning_application:, state: "open")
        visit "/planning_applications/#{planning_application.reference}"

        click_link "Check and validate"
        click_link "Send validation decision"
        click_link "Mark the application as valid"

        expect(page).to have_content "Validate application"

        click_button "Mark the application as valid"

        expect(page).to have_content("Application is ready for assessment")
      end
    end
  end

  context "when application has been invalidated" do
    it "does not show the invalidate button when application is invalid" do
      invalid_planning_application = create(:planning_application, :invalidated,
        local_authority: default_local_authority)

      visit "/planning_applications/#{invalid_planning_application.id}"
      click_link "Check and validate"
      click_link "Send validation decision"

      expect(page).to have_content("The application is marked as invalid. The applicant was notified on #{invalid_planning_application.invalidated_at.to_fs}")
    end

    context "when checking documents from Invalidated status" do
      let!(:planning_application) do
        create(:planning_application, :with_boundary_geojson, :invalidated, local_authority: default_local_authority)
      end

      it "allows planning application to be made valid when open validation request exists" do
        create(:additional_document_validation_request, planning_application:, state: "open")

        within(govuk_tab_all) do
          click_link(planning_application.reference)
        end

        click_link "Check and validate"
        click_link "Send validation decision"

        expect(page).to have_content("This application has 1 unresolved validation request and 1 resolved validation request")

        click_link "Mark the application as valid"
        click_button "Mark the application as valid"

        expect(page).to have_content("Application is ready for assessment")
      end
    end
  end

  context "when application has been validated" do
    before do
      planning_application = create(:planning_application, :in_assessment, local_authority: default_local_authority)

      visit "/planning_applications/#{planning_application.reference}"
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

  context "when planning application is in determined state" do
    let!(:determined_planning_application) do
      create(:planning_application, :determined, local_authority: default_local_authority)
    end

    it "does not show validate form" do
      visit "/planning_applications/#{determined_planning_application.id}/documents"

      expect(page).not_to have_content("Check and validate")
    end

    it "does not allow new requests when application is determined" do
      visit "/planning_applications/#{determined_planning_application.id}/validation/validation_requests"

      expect(page).not_to have_button("Mark the application as invalid")
      expect(page).not_to have_button("New request")
      expect(page).not_to have_content("Add all required validation requests for this application")
    end
  end
end
