# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Create a site notice", js: true do
  let(:default_local_authority) { create(:local_authority, :default) }
  let!(:api_user) { create(:api_user, :planx, local_authority: default_local_authority) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }
  let!(:application_type) { create(:application_type, :prior_approval) }

  let!(:planning_application) do
    create(:planning_application,
      :from_planx_prior_approval,
      :with_boundary_geojson,
      :published,
      application_type:,
      local_authority: default_local_authority,
      api_user:,
      agent_email: "agent@example.com",
      applicant_email: "applicant@example.com",
      user: assessor)
  end

  let(:reference) { planning_application.reference }

  around do |example|
    travel_to("2023-02-01") { example.run }
  end

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("BOPS_ENVIRONMENT", "development").and_return("test")
    sign_in(assessor)
    visit "/planning_applications/#{planning_application.reference}/consultation"
  end

  it "allows officers to create a site notice and print it" do
    click_link "Send site notice"
    expect(page).to have_content("Send site notice")

    choose "Yes"

    expect(page).to have_field("Number of site notices", with: 1)

    fill_in "Number of site notices", with: "2"
    fill_in "Where should notices be displayed?", with: "Display on both entrances"

    expect(page).to have_content("Print the site notice")

    fill_in "Day", with: "1"
    fill_in "Month", with: "2"
    fill_in "Year", with: "2023"

    click_button "Create site notice", visible: true

    expect(page).to have_current_path("/planning_applications/#{reference}/site_notices/new")
    expect(page).to have_content("Site notice was successfully created")
    expect(page).to have_link("Download site notice PDF", href: "#")

    site_notice = planning_application.reload.site_notice
    expect(site_notice.quantity).to eq(2)
    expect(site_notice.location_instructions).to eq("Display on both entrances")
    expect(site_notice.content).not_to include "This application is subject to an Environmental Impact Assessment (EIA)."
  end

  it "allows officers to create a site notice and email it to the agent" do
    click_link "Send site notice"
    expect(page).to have_content("Send site notice")

    choose "Yes"

    expect(page).to have_field("Number of site notices", with: 1)
    expect(page).to have_content("Optional. Anything you add here may be shared with the recipient (including the applicant).")

    fill_in "Number of site notices", with: "4"
    fill_in "Where should notices be displayed?", with: "Attach near the front gate and rear alley"

    expect(page).to have_content("Email the site notice")

    choose "Send it by email to applicant"

    click_button "Email site notice and mark as complete"
    expect(page).to have_current_path("/planning_applications/#{reference}/consultation")
    expect(page).to have_content("Site notice was successfully emailed")

    perform_enqueued_jobs
    email_notification = ActionMailer::Base.deliveries.last

    expect(email_notification.to).to contain_exactly(planning_application.agent_email)
    expect(email_notification.subject).to eq("Display site notice for your application 23-00100-PA1A")
  end

  it "sends it to the applicant if agent email is not present" do
    planning_application.update(agent_email: "")

    click_link "Send site notice"

    choose "Yes"

    expect(page).to have_field("Number of site notices", with: 1)

    fill_in "Number of site notices", with: "4"
    fill_in "Where should notices be displayed?", with: "Attach near the front gate and rear alley"

    choose "Send it by email to applicant"

    click_button "Email site notice and mark as complete"
    expect(page).to have_current_path("/planning_applications/#{reference}/consultation")
    expect(page).to have_content("Site notice was successfully emailed")

    perform_enqueued_jobs
    email_notification = ActionMailer::Base.deliveries.last

    expect(email_notification.to).to contain_exactly(planning_application.applicant_email)
    expect(email_notification.subject).to eq("Display site notice for your application 23-00100-PA1A")
  end

  it "allows officers to create a site notice and email it to the internal team" do
    click_link "Send site notice"
    expect(page).to have_content("Send site notice")

    choose "Yes"

    expect(page).to have_field("Number of site notices", with: 1)

    fill_in "Number of site notices", with: "3"
    fill_in "Where should notices be displayed?", with: "Corner by the substation and rear alley"

    expect(page).to have_content("Email the site notice")

    choose "Send it by email to internal team to post"
    fill_in "Internal team email", with: "invalidemail.com"
    click_button "Email site notice and mark as complete"

    expect(page).to have_selector("[role=alert] li", text: "Internal team email is invalid")

    choose "Send it by email to internal team to post"
    fill_in "Internal team email", with: "internal@email.com"

    click_button "Email site notice and mark as complete"
    expect(page).to have_current_path("/planning_applications/#{reference}/consultation")
    expect(page).to have_content("Site notice was successfully emailed")

    perform_enqueued_jobs
    email_notification = ActionMailer::Base.deliveries.last

    expect(email_notification.to).to contain_exactly("internal@email.com")
    expect(email_notification.subject).to eq("Site notice for application number 23-00100-PA1A")
    expect(email_notification.body.encoded).to include("Number of site notices requested: 3")
    expect(email_notification.body.encoded)
      .to include("Location instructions: Corner by the substation and rear alley")
  end

  it "allows officers to confirm site notice is not needed" do
    click_link "Send site notice"

    choose "No"

    click_button "Save and mark as complete", visible: true
    expect(page).to have_current_path("/planning_applications/#{reference}/consultation")
    expect(page).not_to have_content("Confirm site notice is in place")
  end

  context "when it's an EIA application" do
    before do
      create(:environment_impact_assessment, planning_application:)
    end

    it "has different content" do
      click_link "Send site notice"
      expect(page).to have_content("Send site notice")
      expect(page).to have_content("Subject to EIA")

      choose "Yes"

      expect(page).to have_content("Print the site notice")

      fill_in "Day", with: "1"
      fill_in "Month", with: "2"
      fill_in "Year", with: "2023"

      click_button "Create site notice", visible: true
      expect(page).to have_current_path("/planning_applications/#{reference}/site_notices/new")
      expect(page).to have_content("Site notice was successfully created")
      expect(page).to have_link("Download site notice PDF", href: "#")

      expect(planning_application.site_notice.content).to include "This application is subject to an Environmental Impact Assessment (EIA)."
      expect(planning_application.site_notice.content).not_to include "View a hard copy of the Environment Statement"
    end

    it "contains the address and fee to get hard copy if included in EIA" do
      planning_application.environment_impact_assessment.update(address: "123 street", fee: 19, email_address: "planner@council.com")
      click_link "Send site notice"
      expect(page).to have_content("Send site notice")
      expect(page).to have_content("Subject to EIA")

      choose "Yes"

      expect(page).to have_content("Print the site notice")

      fill_in "Day", with: "1"
      fill_in "Month", with: "2"
      fill_in "Year", with: "2023"

      click_button "Create site notice", visible: true
      expect(page).to have_current_path("/planning_applications/#{reference}/site_notices/new")
      expect(page).to have_content("Site notice was successfully created")
      expect(page).to have_link("Download site notice PDF", href: "#")

      expect(planning_application.site_notice.content).to include "This application is subject to an Environmental Impact Assessment (EIA)."
      expect(planning_application.site_notice.content).to include "You can request a hard copy for a fee of £19 by emailing planner@council.com or in person at 123 street."
    end
  end
end
