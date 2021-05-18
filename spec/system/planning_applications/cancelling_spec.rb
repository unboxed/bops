# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning Application Assessment", type: :system do
  let!(:assessor) { create :user, :assessor, local_authority: @default_local_authority }

  let!(:planning_application) do
    create :planning_application, :not_started, local_authority: @default_local_authority
  end

  before do
    sign_in assessor
    visit planning_application_path(planning_application)
  end

  context "for planning application that is not started" do
    it "can withdraw an application" do
      click_link "Cancel application"
      choose "Withdrawn by applicant"
      fill_in "Can you provide more detail?", with: "Withdrawn reason"
      click_button "Save"

      expect(page).to have_content("Application has been withdrawn")
      planning_application.reload
      expect(planning_application.status).to eq("withdrawn")
      expect(planning_application.cancellation_comment).to eq("Withdrawn reason")
      expect(page).not_to have_content("Assigned to:")

      click_button "Key application dates"
      click_link "Activity log"

      expect(page).to have_text("Application withdrawn")
      expect(page).to have_text(assessor.name)
      expect(page).to have_text(Audit.last.created_at.in_time_zone("London").strftime("%d-%m-%Y %H:%M"))
    end

    it "can return an application" do
      click_link "Cancel application"
      choose "Returned as invalid"
      fill_in "Can you provide more detail?", with: "Returned reason"
      click_button "Save"

      expect(page).to have_content("Application has been returned")
      planning_application.reload
      expect(planning_application.status).to eq("returned")
      expect(planning_application.cancellation_comment).to eq("Returned reason")
      expect(page).not_to have_content("Assigned to:")

      click_button "Key application dates"
      click_link "Activity log"

      expect(page).to have_text("Application returned")
      expect(page).to have_text(assessor.name)
      expect(page).to have_text(Audit.last.created_at.in_time_zone("London").strftime("%d-%m-%Y %H:%M"))
    end

    it "errors if no option chosen" do
      click_link "Cancel application"
      click_button "Save"

      expect(page).to have_content("Please select one of the below options")
      planning_application.reload
      expect(planning_application.status).to eq("not_started")
    end
  end

  context "for planning application that has been determined" do
    let!(:planning_application) do
      create :planning_application, :determined, local_authority: @default_local_authority
    end

    it "prevents cancelling" do
      expect(page).not_to have_link "Cancel application"
      visit cancel_confirmation_planning_application_path(planning_application)
      expect(page).to have_content("This application has been determined and cannot be cancelled")
    end
  end
end
