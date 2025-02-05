# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Meeting" do
  let!(:local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority:) }
  let!(:application_type) { create(:application_type, :pre_application) }

  let!(:planning_application) do
    create(:planning_application, :from_planx_prior_approval,
      application_type:, local_authority:)
  end

  before do
    travel_to("2024-12-24")
    sign_in(assessor)
    visit "/planning_applications/#{planning_application.reference}"
  end

  context "when a meeting is not required" do
    it "does not show the meeting item in the tasklist" do
      click_link "Check and assess"
      expect(page).not_to have_css("#meeting")
    end
  end

  context "when a meeting is required" do
    let!(:additional_service) { create(:additional_service, :with_meeting, planning_application: planning_application) }

    it "shows the meeting item in the tasklist" do
      click_link "Check and assess"
      within("#additional-services-tasks") do
        expect(page).to have_css("#meeting")
      end
    end

    it "I can add a new meeting record" do
      click_link "Check and assess"
      click_link "Meeting"
      expect(page).to have_selector("h1", text: "Add a meeting")

      fill_in "Day", with: "12"
      fill_in "Month", with: "12"
      fill_in "Year", with: "2024"
      fill_in "Add notes (optional)", with: "Met with applicant"
      click_button "Save and mark as complete"

      expect(page).to have_content("Meeting record was successfully added.")

      within("#meeting") do
        expect(page).to have_content("Completed")
      end

      expect(page).to have_link(
        "Meeting",
        href: "/planning_applications/#{planning_application.reference}/assessment/meetings"
      )

      click_link "Meeting"

      within(".govuk-table") do
        expect(page).to have_selector("caption", text: "Meeting history")
        expect(page).to have_content("Met with applicant")
        expect(page).to have_content("12 December 2024")
        expect(page).to have_content(assessor.name)
      end
    end

    context "when there are validation errors" do
      before do
        click_link "Check and assess"
        click_link "Meeting"
      end

      it "there is a validation error when no date is entered" do
        click_button "Save and mark as complete"

        within("#meeting-occurred-at-error") do
          expect(page).to have_content("Provide the date when the meeting took place")
        end
      end

      it "I can't add a meeting after the current date" do
        fill_in "Day", with: "1"
        fill_in "Month", with: "1"
        fill_in "Year", with: "2026"
        click_button "Save and mark as complete"

        expect(page).to have_content "The date the meeting took place must be on or before today"
      end

      it "I can't add an incomplete meeting date" do
        fill_in "Day", with: "1"
        fill_in "Month", with: "1"
        click_button "Save and mark as complete"

        expect(page).to have_content "The date the meeting took place must be a valid date"
      end
    end

    context "when a meeting record exists" do
      let!(:meeting) { create(:meeting, planning_application: planning_application) }

      before do
        click_link "Check and assess"
        click_link "Meeting"
      end

      it "I can see an existing meeting record" do
        within(".govuk-table") do
          expect(page).to have_content(meeting.comment)
          expect(page).to have_content(meeting.occurred_at&.to_date&.to_fs)
          expect(page).to have_content(meeting.created_by.name)
        end
      end
    end
  end
end
