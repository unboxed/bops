# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Confirm site notice", js: true do
  let!(:api_user) { create(:api_user, name: "PlanX") }
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }
  let!(:application_type) { create(:application_type, :prior_approval) }

  let!(:planning_application) do
    create(:planning_application,
           :from_planx_prior_approval,
           :with_boundary_geojson,
           application_type:,
           local_authority: default_local_authority,
           api_user:,
           agent_email: "agent@example.com",
           applicant_email: "applicant@example.com",
           make_public: true)
  end

  let!(:consultation) { planning_application.consultation }

  let!(:site_notice) { create(:site_notice, planning_application:) }
  let!(:audit) { create(:audit, planning_application:, activity_type: "site_notice_created", audit_comment: "Site notice was emailed to the applicant") }

  before do
    sign_in(assessor)

    visit planning_application_consultations_path(planning_application)
  end

  it "allows planning officer to update displayed at date" do
    click_link "Confirm site notice"

    expect(page).to have_content "Site notice was emailed to the applicant"
    expect(page).to have_content audit.created_at.to_fs(:day_month_year_slashes).to_s

    fill_in "Day", with: "01"
    fill_in "Month", with: "02"
    fill_in "Year", with: "2023"

    # Can't upload docs via Capybara yet
    create(:document, site_notice:)

    click_button "Save and mark as complete"

    expect(page).to have_content("Site notice was successfully updated")

    expect(list_item("Confirm site notice")).to have_content("Complete")

    click_link "Confirm site notice"

    expect(page).to have_content("1 February 2023")

    expect(consultation.reload.end_date.to_fs(:day_month_year_slashes)).to eq "22/02/2023"
  end
end
