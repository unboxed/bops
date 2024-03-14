# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Send notification to neighbours of committee" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:reviewer) do
    create(:user,
      :reviewer,
      local_authority: default_local_authority)
  end
  let!(:assessor) do
    create(:user,
      :assessor,
      local_authority: default_local_authority)
  end

  before do
    planning_application = create(:planning_application, :in_assessment, local_authority: default_local_authority, user: assessor)
    create(:consultation, planning_application:)

    planning_application.update(decision: "granted", status: "awaiting_determination")

    allow(Current).to receive(:user).and_return(reviewer)

    sign_in reviewer
  end

  context "when the assessor has not recommended the application go to committee" do
    it "does not show the option to send to committee" do
      visit "/planning_applications/#{PlanningApplication.last.id}/review/tasks"

      expect(page).to have_content("Review and sign-off")

      expect(page).not_to have_content "Notify neighbours of committee meeting"
    end
  end

  context "when the assessor has recommended the application go to committee" do
    before do
      planning_application = create(:planning_application, :in_assessment, local_authority: default_local_authority, user: assessor)
      create(:committee_decision, planning_application: PlanningApplication.last, recommend: true, reasons: ["The first reason"])
      consultation = create(:consultation, planning_application:)

      planning_application.update(decision: "granted", status: "awaiting_determination")

      neighbour = create(:neighbour, consultation:)
      create(:neighbour_response, email: "my.email@example.com", neighbour:)
      neighbour2 = create(:neighbour, consultation:, address: "123 street, london, E1")
      create(:neighbour_response, email: nil, neighbour: neighbour2)
    end

    it "can send notifications to neighbours who have commented" do
      visit "/planning_applications/#{PlanningApplication.last.id}/review/tasks"

      click_link "Notify neighbours of committee meeting"

      expect(page).to have_content "Application going to committee"
      expect(page).to have_content "The first reason"

      within_fieldset("Enter date of meeting") do
        fill_in "Day", with: "2"
        fill_in "Month", with: "2"
        fill_in "Year", with: "2022"
      end

      fill_in "Enter location", with: "Unboxed Consulting"
      fill_in "Enter link", with: "unboxed.co"
      fill_in "Enter time of meeting", with: "10.30am"
      fill_in "Enter time of meeting", with: "10.30am"

      within_fieldset("Enter deadline for late comments to be received by") do
        fill_in "Day", with: "2"
        fill_in "Month", with: "2"
        fill_in "Year", with: "2022"
      end

      click_button "Send notification"

      expect(page).to have_content "Notifications sent to neighbours and application in committee"

      expect(SendCommitteeDecisionEmailJob).to have_been_enqueued
      # Did try testing letter sending service had been called, but was too difficult given the order of tests and when data got saved
      expect(NeighbourLetter.last.text).to include("This application is scheduled to be determined")

      click_link "Notify neighbours of committee meeting"

      expect(page).to have_content "Date of meeting"
      expect(page).to have_content "2 February 2022"

      click_link "Update meeting details"

      fill_in "Enter link", with: "www.unboxed.co"

      click_button "Send notification"

      expect(page).to have_content "Notifications sent to neighbours and application in committee"

      expect(SendCommitteeDecisionEmailJob).to have_been_enqueued.at_least(2).times
      # Did try testing letter sending service had been called, but was too difficult given the order of tests and when data got saved
      expect(NeighbourLetter.last.text).to include("www.unboxed.co")
    end

    it "shows errors" do
      visit "/planning_applications/#{PlanningApplication.last.id}/review/tasks"

      click_link "Notify neighbours of committee meeting"

      click_button "Send notification"

      expect(page).to have_content "Date of committee can't be blank, Location can't be blank, Link can't be blank, Time can't be blank, Late comments deadline can't be blank"
    end
  end
end
