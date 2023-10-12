# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Press notice" do
  let!(:local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority:) }
  let!(:planning_application) do
    create(:planning_application, :prior_approval, local_authority:)
  end

  before do
    sign_in assessor

    planning_application.consultation.update(end_date: Time.zone.local(2023, 9, 15, 12))
    visit planning_application_path(planning_application)
  end

  context "when there is a consultation end date" do
    it "displays the consultation end date" do
      click_link "Consultees, neighbours and publicity"

      expect(page).to have_content("Consultation end date: 15 September 2023")
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
          href: edit_planning_application_confirm_press_notice_path(planning_application, press_notice)
        )
      end
    end
  end
end
