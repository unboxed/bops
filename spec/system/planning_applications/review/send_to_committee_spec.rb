# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reviewing sign-off" do
  let(:default_local_authority) { create(:local_authority, :default) }
  let!(:reviewer) do
    create(:user,
      :reviewer,
      local_authority: default_local_authority)
  end
  let!(:assessor) do
    create(:user,
      :assessor,
      name: "The name of assessor",
      local_authority: default_local_authority)
  end
  let(:user) { create(:user) }

  let!(:planning_application) do
    travel_to("2022-01-01") do
      create(
        :planning_application,
        :awaiting_determination,
        local_authority: default_local_authority,
        decision: "granted",
        user:
      )
    end
  end

  let!(:consultation) do
    create(:consultation, planning_application:)
  end

  before do
    sign_in reviewer
  end

  context "when the assessor has not recommended the application go to committee" do
    it "does not show the option to send to committee" do
      visit "/planning_applications/#{planning_application.id}/review/tasks"

      expect(page).not_to have_content "Notify neighbours of committee meeting"
    end
  end

  context "when the assessor has recommended the application go to committee" do
    before do
      create(:committee_decision, planning_application:, recommend: true, reasons: ["The first reason"])
      neighbour = create(:neighbour, consultation:)
      create(:neighbour_response, neighbour:)
      create(:neighbour, consultation:, address: "123 street, london, E1")
    end

    it "can send notifications to neighbours who have commented" do
      visit "/planning_applications/#{planning_application.id}/review/tasks"

      click_link "Notify neighbours of committee meeting"

      expect(page).to have_content "Application going to committee"
      expect(page).to have_content "The first reason"

      fill_in "Day", with: "2"
      fill_in "Month", with: "2"
      fill_in "Year", with: "2022"

      fill_in "Enter location", with: "Unboxed Consulting"
      fill_in "Enter link (optional)", with: "unboxed.co"
      fill_in "Enter time of meeting", with: "10.30am"

      click_button "Send notification"
    end
  end
end
