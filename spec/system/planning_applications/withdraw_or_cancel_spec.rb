# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Withdraw or cancel" do
  let(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application, :not_started, local_authority: default_local_authority)
  end

  before do
    sign_in assessor
    visit planning_application_path(planning_application)
  end

  it "displays the planning application address and reference" do
    click_link "Withdraw or cancel application"

    expect(page).to have_content(planning_application.full_address)
    expect(page).to have_content(planning_application.reference)
  end

  context "when planning application that is not started" do
    it "can withdraw an application" do
      click_link "Withdraw or cancel application"
      choose "Withdrawn by applicant"
      fill_in "Provide a reason", with: "Withdrawn reason"
      click_button "Withdraw or cancel application"

      expect(page).to have_content("Application has been withdrawn")
      planning_application.reload
      expect(planning_application.status).to eq("withdrawn")
      expect(planning_application.closed_or_cancellation_comment).to eq("Withdrawn reason")
      expect(page).not_to have_content("Assigned to:")
    end

    it "can return an application" do
      click_link "Withdraw or cancel application"
      choose "Returned as invalid"
      fill_in "Provide a reason", with: "Returned reason"
      click_button "Withdraw or cancel application"

      expect(page).to have_content("Application has been returned")
      planning_application.reload
      expect(planning_application.status).to eq("returned")
      expect(planning_application.closed_or_cancellation_comment).to eq("Returned reason")
      expect(page).not_to have_content("Assigned to:")
    end

    it "can close an application" do
      click_link "Withdraw or cancel application"
      choose "Cancelled for other reason"
      fill_in "Provide a reason", with: "Closed reason"
      click_button "Withdraw or cancel application"

      expect(page).to have_content("Application has been closed")
      within(".govuk-tag--grey") do
        expect(page).to have_content("Closed")
      end
      expect(page).to have_content("Reason for being closed: Closed reason")
      expect(page).to have_content("Closed at: #{planning_application.closed_at}")
      planning_application.reload
      expect(planning_application.status).to eq("closed")
      expect(planning_application.closed_or_cancellation_comment).to eq("Closed reason")
      expect(page).not_to have_content("Assigned to:")
    end

    it "errors if no option chosen" do
      click_link "Withdraw or cancel application"
      click_button "Withdraw or cancel application"

      expect(page).to have_content("Please select one of the below options")
      planning_application.reload
      expect(planning_application.status).to eq("not_started")
    end
  end

  context "when planning application has been determined" do
    let!(:planning_application) do
      create(:planning_application, :determined, local_authority: default_local_authority)
    end

    it "prevents closing or cancelling" do
      expect(page).not_to have_link "Withdraw or cancel application"
      visit planning_application_withdraw_or_cancel_path(planning_application)
      expect(page).to have_content("This application has been determined and cannot be withdrawn or cancelled")
    end
  end

  context "when planning application has been closed" do
    let!(:planning_application) do
      create(:planning_application, :closed, local_authority: default_local_authority)
    end

    it "prevents closing or cancelling" do
      expect(page).not_to have_link "Withdraw or cancel application"
      visit planning_application_withdraw_or_cancel_path(planning_application)
      expect(page).to have_content("This application has already been withdrawn or cancelled.")
    end
  end

  context "when uploading a supporting document" do
    context "when providing a file with a permitted extension" do
      it "withdraws or cancels the planning application with a redacted document" do
        visit planning_application_withdraw_or_cancel_path(planning_application)
        expect(page).to have_content("Upload a supporting document")
        expect(page).to have_content("Optionally add a redacted document to support the decision")

        choose "Cancelled for other reason"
        fill_in "Provide a reason", with: "Cancelled reason"

        attach_file(
          "Upload a supporting document",
          "spec/fixtures/images/proposed-roofplan.png"
        )

        click_button("Withdraw or cancel application")

        expect(page).to have_content("Application has been closed")

        expect(planning_application.reload).to have_attributes(
          closed_or_cancellation_comment: "Cancelled reason",
          status: "closed"
        )

        expect(Audit.last).to have_attributes(
          planning_application_id: planning_application.id,
          activity_type: "closed",
          audit_comment: "Cancelled reason"
        )

        document = planning_application.documents.last
        expect(document.file.filename.to_s).to eq("proposed-roofplan.png")
        expect(document.redacted).to be(true)
      end
    end

    context "when providing a file with an unpermitted extension" do
      it "presents an error" do
        visit planning_application_withdraw_or_cancel_path(planning_application)
        choose "Cancelled for other reason"

        attach_file(
          "Upload a supporting document",
          "spec/fixtures/images/image.gif"
        )

        click_button("Withdraw or cancel application")

        expect(page).to have_content("The selected file must be a PDF, JPG or PNG")
      end
    end
  end
end
