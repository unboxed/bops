# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Consultation" do
  let!(:local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority:) }
  let!(:planning_application) do
    create(:planning_application, :prior_approval, local_authority:)
  end

  before do
    sign_in assessor

    planning_application.consultation.update(start_date: Time.zone.local(2023, 8, 15, 12), end_date: Time.zone.local(2023, 9, 15, 12))
    visit "/planning_applications/#{planning_application.id}"
  end

  context "when there is a consultation end date" do
    it "displays the consultation end date" do
      click_link "Consultees, neighbours and publicity"

      expect(page).to have_content("Consultation end date: 15 September 2023")
    end

    it "I can edit the consultation end date" do
      click_link "Consultees, neighbours and publicity"

      within("#edit-consultation-end-date") do
        click_link "Change"
      end

      fill_in "Day", with: "03"
      fill_in "Month", with: ""
      fill_in "Year", with: ""

      click_button "Save"
      within(".govuk-error-summary") do
        expect(page).to have_content("End date is not a valid date")
      end

      fill_in "Day", with: "03"
      fill_in "Month", with: "01"
      fill_in "Year", with: "2023"
      click_button "Save"
      within(".govuk-error-summary") do
        expect(page).to have_content("End date is not on or after 15/08/2023")
      end

      fill_in "Day", with: "20"
      fill_in "Month", with: "09"
      fill_in "Year", with: "2023"
      click_button "Save"
      expect(page).to have_content("Consultation was successfully updated.")
      expect(page).to have_content("Consultation end date: 20 September 2023")
    end
  end

  context "when there is an oustanding action to take that has an effect on the consultation end date" do
    let!(:press_notice) do
      create(:press_notice, :required, planning_application:, published_at: nil)
    end
    let!(:site_notice) do
      create(:site_notice, planning_application:, displayed_at: nil)
    end

    before do
      travel_to(Time.zone.local(2023, 3, 15, 12))
      click_link "Consultees, neighbours and publicity"
    end

    it "displays a warning if there is a required site notice without a displayed at date" do
      within("#confirm-site-notice-warning .govuk-warning-text") do
        expect(page).to have_link(
          "Confirm site notice display date",
          href: edit_planning_application_site_notice_path(planning_application, site_notice)
        )
      end
    end

    it "displays a warning if there is a required press notice without a published at date" do
      within("#confirm-press-notice-warning .govuk-warning-text") do
        expect(page).to have_link(
          "Confirm press notice publication date",
          href: "/planning_applications/#{planning_application.id}/press_notice/confirmation"
        )
      end
    end
  end
end
