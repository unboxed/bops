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
    click_link "Check and assess"
    click_link "Meeting"
  end

  context "when a meeting is required" do
    let!(:additional_service) { create(:additional_service, :with_meeting, planning_application: planning_application) }

    it "I can add a new meeting record" do
      expect(page).to have_selector("h1", text: "Meeting")

      fill_in "Day", with: "12"
      fill_in "Month", with: "12"
      fill_in "Year", with: "2024"
      fill_in "Add notes (optional)", with: "Met with applicant"
      click_button "Add meeting"

      expect(page).to have_content("Meeting successfully recorded")

      within(".govuk-table") do
        expect(page).to have_selector("caption", text: "Meeting history")
        expect(page).to have_content("Met with applicant")
        expect(page).to have_content("12 December 2024")
        expect(page).to have_content(assessor.name)
      end
    end

    context "when there are validation errors" do
      it "there is a validation error when no date is entered" do
        click_button "Add meeting"

        expect(page).to have_content("Enter the date of the meeting")
      end

      it "I can't add a meeting after the current date" do
        fill_in "Day", with: "1"
        fill_in "Month", with: "1"
        fill_in "Year", with: "2026"
        click_button "Add meeting"

        expect(page).to have_content "Enter a date on or before today’s date"
      end

      it "I can't add an incomplete meeting date" do
        fill_in "Day", with: "1"
        fill_in "Month", with: "1"
        click_button "Add meeting"

        expect(page).to have_content "Enter a valid date for the meeting"
      end
    end

    context "when a meeting record exists" do
      let!(:meeting) { create(:meeting, planning_application: planning_application) }

      before { page.refresh }

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
