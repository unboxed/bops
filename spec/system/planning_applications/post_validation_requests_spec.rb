# frozen_string_literal: true

require "rails_helper"

RSpec.describe "post validation requests" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  before do
    sign_in assessor

    visit "/planning_applications/#{planning_application.id}"
  end

  context "when application has been validated" do
    let!(:planning_application) do
      create(:planning_application, :in_assessment, local_authority: default_local_authority)
    end

    it "lets the assessor create an additional document request" do
      visit "/planning_applications/#{planning_application.id}/documents"
      click_link("Request a new document")
      fill_in("Please specify the new document type:", with: "Floor plan")

      fill_in(
        "Please specify the reason you have requested this document?",
        with: "Existing document inaccurate"
      )

      click_button("Send request")

      expect(page).to have_content(
        "Additional document request successfully created."
      )

      click_link("Application")
      click_link("Review non-validation requests")

      expect(page).to have_content(planning_application.full_address)
      expect(page).to have_content(planning_application.reference)

      within(".validation-requests-table") do
        expect(page).to have_content("Floor plan")
      end

      visit "/planning_applications/#{planning_application.id}/documents"

      within("#additional-document-validation-requests-table") do
        expect(page).to have_content("Document requested: Floor plan")
      end
    end

    context "when additional document request exists" do
      before do
        create(
          :additional_document_validation_request,
          planning_application:,
          document_request_type: "Floor plan",
          reason: "Existing document inaccurate"
        )
      end

      it "does not let the assessor submit a recommendation" do
        click_link("Check and assess")
        click_link("Make draft recommendation")

        choose("Yes")

        fill_in(
          "State the reasons why this application is, or is not lawful.",
          with: "GDPO compliant"
        )

        fill_in(
          "Provide supporting information for your manager.",
          with: "LGTM!"
        )

        click_button("Save and mark as complete")
        click_link("Review and submit recommendation")
        click_button("Submit recommendation")

        expect(page).to have_content(
          "This application has open non-validation requests."
        )
      end

      it "lets the assessor cancel the request" do
        visit "/planning_applications/#{planning_application.id}/documents"
        document_row = row_with_content("Document requested: Floor plan")

        within(document_row) do
          click_link("Cancel request")
        end

        fill_in(
          "Explain to the applicant why this request is being cancelled",
          with: "Requested in error"
        )

        click_button("Confirm cancellation")

        expect(page).to have_content(
          "Additional document request successfully cancelled."
        )

        within(".cancelled-requests") do
          expect(page).to have_content("Requested in error")
        end

        visit "/planning_applications/#{planning_application.id}/documents"

        expect(page).not_to have_content("Document requested: Floor plan")
      end

      it "does not show request on validation documents page" do
        visit "/planning_applications/#{planning_application.id}/validation_documents"
        expect(page).not_to have_content("Document requested: Floor plan")
      end
    end

    context "when viewing the post validation requests table" do
      let!(:planning_application) do
        create(:planning_application, :invalidated, local_authority: default_local_authority)
      end

      before do
        create(:red_line_boundary_change_validation_request, :closed, planning_application:)
        create(:red_line_boundary_change_validation_request, :cancelled, planning_application:)

        planning_application.start!

        visit "/planning_applications/#{planning_application.id}/validation/validation_requests/post_validation_requests"
      end

      it "does not display any pre validation requests" do
        expect(page).not_to have_content("Red line boundary changes")
        expect(page).not_to have_content("View request red line boundary")
        expect(page).not_to have_content("Cancelled requests")

        # check pre valiation requests table
        visit "/planning_applications/#{planning_application.id}/validation/validation_requests"
        within(".validation-requests-table") do
          expect(page).to have_content("Red line boundary changes")
          expect(page).to have_content("View request red line boundary")
        end

        within(".cancelled-requests") do
          expect(page).to have_content("Red line boundary changes")
        end
      end
    end

    context "when viewing the pre validation requests table" do
      let!(:planning_application) do
        create(:planning_application, :in_assessment, local_authority: default_local_authority)
      end

      before do
        create(:red_line_boundary_change_validation_request, :closed, planning_application:)
        create(:red_line_boundary_change_validation_request, :cancelled, planning_application:)

        create(
          :description_change_validation_request,
          :cancelled,
          planning_application:,
          proposed_description: "New description 1"
        )

        create(
          :description_change_validation_request,
          planning_application:,
          proposed_description: "New description 2"
        )

        visit "/planning_applications/#{planning_application.id}/validation/validation_requests"
      end

      it "does not display any post validation requests" do
        expect(page).not_to have_content("Red line boundary changes")
        expect(page).not_to have_content("View request red line boundary")
        expect(page).not_to have_content("Cancelled requests")
        expect(page).not_to have_content("New description 1")
        expect(page).not_to have_content("New description 2")

        # check post valiation requests table
        visit "/planning_applications/#{planning_application.id}/validation/validation_requests/post_validation_requests"
        within(".validation-requests-table") do
          expect(page).to have_content("Red line boundary changes")
          expect(page).to have_content("View request red line boundary")
          expect(page).to have_content("New description 2")
        end

        within(".cancelled-requests") do
          expect(page).to have_content("Red line boundary changes")
          expect(page).to have_content("New description 1")
        end
      end
    end
  end

  context "when application is not started" do
    let!(:planning_application) do
      create(:planning_application, :not_started, local_authority: default_local_authority)
    end

    it "does not allow you to view post validation requests" do
      expect(page).not_to have_link("Review non-validation requests")

      # visit url directly
      visit "/planning_applications/#{planning_application.id}/validation/validation_requests/post_validation_requests"
      expect(page).to have_content("forbidden")
    end
  end

  context "when application is invalidated" do
    let!(:planning_application) do
      create(:planning_application, :invalidated, local_authority: default_local_authority)
    end

    it "does not allow you to view post validation requests" do
      expect(page).not_to have_link("Review non-validation requests")

      # visit url directly
      visit "/planning_applications/#{planning_application.id}/validation/validation_requests/post_validation_requests"
      expect(page).to have_content("forbidden")
    end
  end

  context "when the application is awaiting determination" do
    let(:planning_application) do
      create(
        :planning_application,
        :awaiting_determination,
        local_authority: default_local_authority
      )
    end

    it "lets the assessor create an additional document request" do
      visit "/planning_applications/#{planning_application.id}/documents"
      click_link("Request a new document")
      fill_in("Please specify the new document type:", with: "Floor plan")

      fill_in(
        "Please specify the reason you have requested this document?",
        with: "Existing document inaccurate"
      )

      click_button("Send request")

      expect(page).to have_content(
        "Additional document request successfully created."
      )
    end
  end
end
