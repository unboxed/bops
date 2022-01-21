# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning Application Assessment", type: :system do
  let(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create :user, :assessor, local_authority: default_local_authority }

  let!(:planning_application) do
    create :planning_application, :not_started, local_authority: default_local_authority
  end

  before do
    sign_in assessor
    visit planning_application_path(planning_application)
  end

  context "when planning application that is not started" do
    it "can withdraw an application" do
      click_link "Close or cancel application"
      choose "Withdrawn by applicant"
      fill_in "Provide a reason", with: "Withdrawn reason"
      click_button "Save"

      expect(page).to have_content("Application has been withdrawn")
      planning_application.reload
      expect(planning_application.status).to eq("withdrawn")
      expect(planning_application.closed_or_cancellation_comment).to eq("Withdrawn reason")
      expect(page).not_to have_content("Assigned to:")
    end

    it "can return an application" do
      click_link "Close or cancel application"
      choose "Returned as invalid"
      fill_in "Provide a reason", with: "Returned reason"
      click_button "Save"

      expect(page).to have_content("Application has been returned")
      planning_application.reload
      expect(planning_application.status).to eq("returned")
      expect(planning_application.closed_or_cancellation_comment).to eq("Returned reason")
      expect(page).not_to have_content("Assigned to:")
    end

    it "can close an application" do
      click_link "Close or cancel application"
      choose "Closed for other reason"
      fill_in "Provide a reason", with: "Closed reason"
      click_button "Save"

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
      click_link "Close or cancel application"
      click_button "Save"

      expect(page).to have_content("Please select one of the below options")
      planning_application.reload
      expect(planning_application.status).to eq("not_started")
    end
  end

  context "when planning application has been determined" do
    let!(:planning_application) do
      create :planning_application, :determined, local_authority: default_local_authority
    end

    it "prevents closing or cancelling" do
      expect(page).not_to have_link "Close or cancel application"
      visit close_or_cancel_confirmation_planning_application_path(planning_application)
      expect(page).to have_content("This application has been determined and cannot be cancelled")
    end
  end

  context "when planning application has been closed" do
    let!(:planning_application) do
      create :planning_application, :closed, local_authority: default_local_authority
    end

    it "prevents closing or cancelling" do
      expect(page).not_to have_link "Close or cancel application"
      visit close_or_cancel_confirmation_planning_application_path(planning_application)
      expect(page).to have_content("This application has already been closed or cancelled.")
    end
  end
end
