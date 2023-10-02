# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Create a site notice", js: true do
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
           user: assessor,
           make_public: true)
  end

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("BOPS_ENVIRONMENT", "development").and_return("test")
    allow(ENV).to receive(:fetch).with("APPLICANTS_APP_HOST").and_return("example.com")
    sign_in(assessor)
    visit planning_application_consultations_path(planning_application)
  end

  it "allows officers to create a site notice and print it" do
    click_link "Send site notice"
    expect(page).to have_content("Send site notice")

    choose "Yes"

    expect(page).to have_content("Print the site notice")

    fill_in "Day", with: "1"
    fill_in "Month", with: "2"
    fill_in "Year", with: "2023"

    click_button "Create PDF and mark as complete"

    expect(page).to have_content "Site notice was successfully created"
  end

  it "allows officers to create a site notice and email it to the applicant" do
    click_link "Send site notice"
    expect(page).to have_content("Send site notice")

    choose "Yes"

    expect(page).to have_content("Email the site notice")

    choose "Send it by email to applicant"

    click_button "Email site notice and mark as complete"

    perform_enqueued_jobs
    email_notification = ActionMailer::Base.deliveries.last

    expect(email_notification.to).to contain_exactly(planning_application.applicant_email)

    expect(email_notification.subject).to eq("Display site notice for your application 23-00100-PA")

    expect(page).to have_content "Site notice was successfully emailed"
  end

  it "allows officers to create a site notice and email it to the internal team" do
    click_link "Send site notice"
    expect(page).to have_content("Send site notice")

    choose "Yes"

    expect(page).to have_content("Email the site notice")

    choose "Send it by email to internal team to post"

    fill_in "Internal team email", with: "internal@email.com"

    click_button "Email site notice and mark as complete"

    perform_enqueued_jobs
    email_notification = ActionMailer::Base.deliveries.last

    expect(email_notification.to).to contain_exactly("internal@email.com")

    expect(email_notification.subject).to eq("Site notice for application number 23-00100-PA")

    expect(page).to have_content "Site notice was successfully emailed"
  end

  it "allows officers to confirm site notice is not needed" do
    click_link "Send site notice"

    choose "No"

    click_button "Save and mark as complete"

    expect(page).not_to have_content "Confirm site notice is in place"
  end
end
