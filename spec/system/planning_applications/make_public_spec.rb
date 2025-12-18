# frozen_string_literal: true

require "rails_helper"

RSpec.describe "making planning application public" do
  let!(:local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority:) }
  let!(:planning_application) { create(:planning_application, :planning_permission, local_authority:) }
  let!(:reference) { planning_application.reference }

  around do |example|
    travel_to("2022-01-01") { example.run }
  end

  before do
    sign_in(assessor)
  end

  it "lets a planning application be made public and not" do
    visit "/planning_applications/#{reference}"
    expect(page).to have_content("Public on BOPS Public Portal: No")

    expect {
      visit "/planning_applications/#{reference}/make_public"
      expect(page).to have_content("Make application public")
      expect(page).to have_checked_field("No")

      choose "Yes"

      click_button "Update application"
      expect(page).to have_content("Public on BOPS Public Portal: Yes")
    }.to change {
      [planning_application.reload.published_at, planning_application.consultation.start_date]
    }.from([nil, nil]).to(["2022-01-01".in_time_zone, "2022-01-01".in_time_zone])

    expect {
      visit "/planning_applications/#{reference}/make_public"
      expect(page).to have_content("Make application public")
      expect(page).to have_checked_field("Yes")

      choose "No"

      click_button "Update application"
      expect(page).to have_content("Public on BOPS Public Portal: No")
    }.to change {
      planning_application.reload.published_at
    }.from("2022-01-01".in_time_zone).to(nil)
  end

  context "when the application type is 'preApp'" do
    let!(:planning_application) { create(:planning_application, :pre_application, local_authority:) }

    it "redirects to the assessment tasks page" do
      visit "/planning_applications/#{reference}"
      expect(page).not_to have_content("Public on BOPS Public Portal")

      visit "/planning_applications/#{reference}/make_public"
      expect(page).to have_current_path("/preapps/#{reference}/check-and-assess/check-application/check-application-details")
      expect(page).to have_selector("[role=alert] p", text: "You can’t publish Pre-application Advice on the public portal")
    end
  end
end
