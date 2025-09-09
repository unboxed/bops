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
  let!(:planning_application) do
    create(:planning_application, :planning_permission, :awaiting_determination, :with_recommendation, local_authority: default_local_authority, user: assessor)
  end

  before do
    allow(Current).to receive(:user).and_return(reviewer)
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("BOPS_ENVIRONMENT", "development").and_return("production")

    sign_in reviewer
  end

  context "when the assessor has not recommended the application go to committee" do
    it "does not show the option to send to committee" do
      visit "/planning_applications/#{PlanningApplication.last.id}/review/tasks"

      expect(page).to have_content("Review and sign-off")

      expect(page).not_to have_content "Notify neighbours of committee meeting"
    end
  end

  context "when the application is to be reviewed" do
    before do
      planning_application.request_correction!
      planning_application.committee_decision.update(recommend: true, reasons: ["The first reason"])
      planning_application.committee_decision.current_review.update(review_status: "review_complete", action: "accepted")
    end

    it "does not show the option to send to committee" do
      visit "/planning_applications/#{PlanningApplication.last.id}/review/tasks"

      expect(page).to have_content("Review and sign-off")

      expect(page).not_to have_link "Notify neighbours of committee meeting"
      within("#notify-neighbours-of-committee-meeting") do
        expect(page).to have_content "Cannot start yet"
      end
      within("#update-decision-notice") do
        expect(page).to have_content "Cannot start yet"
      end

      visit "/planning_applications/#{planning_application.reference}/review/committee_decisions/#{planning_application.committee_decision.id}/notifications/edit"
      expect(page).to have_current_path "/planning_applications/#{planning_application.reference}/review/tasks"
    end
  end

  context "when the assessor has recommended the application go to committee" do
    before do
      consultation = planning_application.consultation
      planning_application.committee_decision.update(recommend: true, reasons: ["The first reason"])
      planning_application.committee_decision.current_review.update(review_status: "review_complete", action: "accepted")

      neighbour = create(:neighbour, consultation:)
      create(:neighbour_response, email: "my.email@example.com", neighbour:)
      neighbour2 = create(:neighbour, consultation:, address: "123 street, london, E1")
      create(:neighbour_response, email: nil, neighbour: neighbour2)

      client = double("Notifications::Client")
      letter_response = double("Notifications::Response")
      allow(letter_response).to receive(:id).and_return("12345")
      allow(client).to receive(:send_letter).and_return(letter_response)
      allow(Notifications::Client).to receive(:new).and_return(client)
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

      expect(PlanningApplicationMailer).to receive(:send_committee_decision_mail).once.and_call_original

      click_button "Send notification"

      expect(page).to have_content "Notifications sent to neighbours and application in committee"

      expect(page).to have_content "In committee"

      expect(SendCommitteeDecisionEmailJob).to have_been_enqueued
      # Did try testing letter sending service had been called, but was too difficult given the order of tests and when data got saved
      expect(NeighbourLetter.last.text).to include("This application is scheduled to be determined")

      click_link "Notify neighbours of committee meeting"

      expect(page).to have_content "Date of meeting"
      expect(page).to have_content "2 February 2022"

      click_link "Update meeting details"

      fill_in "Enter link", with: "www.unboxed.co"

      expect(PlanningApplicationMailer).to receive(:send_committee_decision_mail).once

      click_button "Send notification"

      expect(page).to have_content "Notifications sent to neighbours and application in committee"

      expect(SendCommitteeDecisionEmailJob).to have_been_enqueued.at_least(2).times
      # Did try testing letter sending service had been called, but was too difficult given the order of tests and when data got saved
      expect(NeighbourLetter.last.text).to include("www.unboxed.co")
    end

    it "shows errors" do
      visit "/planning_applications/#{PlanningApplication.last.id}/review/tasks"

      click_link "Notify neighbours of committee meeting"

      expect(PlanningApplicationMailer).not_to receive(:send_committee_decision_mail)
      expect(SendCommitteeDecisionEmailJob).not_to have_been_enqueued

      click_button "Send notification"

      expect(page).to have_content "Date of committee can't be blank, Location can't be blank, Link can't be blank, Time can't be blank, Late comments deadline can't be blank"
    end
  end
end
