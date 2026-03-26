# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Send site notice", js: true do
  let(:default_local_authority) { create(:local_authority, :default) }
  let!(:api_user) { create(:api_user, :planx, local_authority: default_local_authority) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }
  let!(:application_type) { create(:application_type, :planning_permission) }

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

  let(:task) { planning_application.case_record.find_task_by_slug_path!("consultees-neighbours-and-publicity/publicity/send-site-notice") }

  around do |example|
    travel_to("2026-02-01") { example.run }
  end

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("BOPS_ENVIRONMENT", "development").and_return("test")
    sign_in(assessor)
    visit "/planning_applications/#{planning_application.reference}"
    click_link "Consultees, neighbours and publicity"
  end

  it "allows officers to create a site notice and print it" do
    within :sidebar do
      click_link "Send site notice"
    end
    expect(page).to have_content("Does this application require a site notice?")
    expect(task.reload).to be_not_started

    choose "Yes"

    expect(page).to have_field("Number of site notices", with: 1)

    fill_in "Number of site notices", with: "2"
    fill_in "Where should notices be displayed?", with: "Display on both entrances"

    expect(page).to have_content("Print the site notice")

    fill_in "Day", with: "1"
    fill_in "Month", with: "2"
    fill_in "Year", with: "2026"

    click_button "Create site notice", visible: true

    expect(page).to have_content("Site notice successfully created")
    expect(planning_application.site_notices.length).to eq(1)
    expect(task.reload).to be_in_progress

    expect(page).to have_link("Download site notice PDF", href: "#")

    site_notice = planning_application.reload.site_notice
    expect(site_notice.quantity).to eq(2)
    expect(site_notice.location_instructions).to eq("Display on both entrances")

    click_button "Save and mark as complete"
    expect(page).to have_content("Successfully saved site notice task")
    expect(task.reload).to be_completed
  end

  it "allows officers to create a site notice and email it to the agent" do
    within :sidebar do
      click_link "Send site notice"
    end

    choose "Yes"

    expect(page).to have_field("Number of site notices", with: 1)
    expect(page).to have_content("Optional. Anything you add here may be shared with the recipient (including the applicant).")

    fill_in "Number of site notices", with: "4"
    fill_in "Where should notices be displayed?", with: "Attach near the front gate and rear alley"

    expect(page).to have_content("Email the site notice")

    choose "Send it by email to applicant"

    click_button "Email site notice"
    expect(page).to have_content("Site notice email successfully sent")
    expect(task.reload).to be_in_progress

    perform_enqueued_jobs
    email_notification = ActionMailer::Base.deliveries.last

    expect(email_notification.to).to contain_exactly(planning_application.agent_email)
    expect(email_notification.subject).to eq("Display site notice for your application 26-00100-HAPP")
  end

  it "sends it to the applicant if agent email is not present" do
    planning_application.update(agent_email: "")

    within :sidebar do
      click_link "Send site notice"
    end

    choose "Yes"

    expect(page).to have_field("Number of site notices", with: 1)

    fill_in "Number of site notices", with: "4"
    fill_in "Where should notices be displayed?", with: "Attach near the front gate and rear alley"

    choose "Send it by email to applicant"

    click_button "Email site notice"
    expect(page).to have_content("Site notice email successfully sent")
    expect(task.reload).to be_in_progress

    perform_enqueued_jobs
    email_notification = ActionMailer::Base.deliveries.last

    expect(email_notification.to).to contain_exactly(planning_application.applicant_email)
    expect(email_notification.subject).to eq("Display site notice for your application 26-00100-HAPP")
  end

  it "allows officers to create a site notice and email it to the internal team" do
    within :sidebar do
      click_link "Send site notice"
    end
    expect(page).to have_content("Send site notice")

    choose "Yes"

    expect(page).to have_field("Number of site notices", with: 1)

    fill_in "Number of site notices", with: "3"
    fill_in "Where should notices be displayed?", with: "Corner by the substation and rear alley"

    expect(page).to have_content("Email the site notice")

    choose "Send it by email to internal team to post"
    fill_in "Internal team email", with: "invalidemail.com"
    click_button "Email site notice"

    expect(page).to have_selector("[role=alert] li", text: "Internal team email is invalid")

    choose "Send it by email to internal team to post"
    fill_in "Internal team email", with: "internal@email.com"

    click_button "Email site notice"
    expect(page).to have_content("Site notice email successfully sent")
    expect(task.reload).to be_in_progress

    perform_enqueued_jobs
    email_notification = ActionMailer::Base.deliveries.last

    expect(email_notification.to).to contain_exactly("internal@email.com")
    expect(email_notification.subject).to eq("Site notice for application number 26-00100-HAPP")
    expect(email_notification.body.encoded).to include("Number of site notices requested: 3")
    expect(email_notification.body.encoded)
      .to include("Location instructions: Corner by the substation and rear alley")
  end

  it "allows officers to confirm site notice is not needed" do
    within :sidebar do
      click_link "Send site notice"
    end
    expect(page).to have_current_path("/planning_applications/#{planning_application.reference}/consultees-neighbours-and-publicity/publicity/send-site-notice")

    choose "No"

    click_button "Save and mark as complete", visible: true
    expect(page).to have_content("Site notice has been marked as not required")
    expect(planning_application.audits.where(activity_type: "site_notice_not_required").length).to eq(1)
  end

  context "when there is an existing site notice" do
    let!(:existing_site_notice) { create(:site_notice, planning_application:) }

    before do
      task.in_progress!

      within :sidebar do
        click_link "Send site notice"
      end
    end

    it "allows officers to add another site notice" do
      find("summary", text: "Add new site notice").click

      within("details") do
        fill_in "Number of site notices", with: "3"
        fill_in "Where should notices be displayed?", with: "Near the main entrance"

        fill_in "Day", with: "5"
        fill_in "Month", with: "2"
        fill_in "Year", with: "2026"

        click_button "Create site notice"
      end

      expect(page).to have_content("Site notice successfully created")
      expect(planning_application.site_notices.length).to eq(2)
      expect(task.reload).to be_in_progress
    end
  end

  context "when it's an EIA application" do
    before do
      create(:environment_impact_assessment, planning_application:)
    end

    it "has different content" do
      within :sidebar do
        click_link "Send site notice"
      end
      expect(page).to have_content("Send site notice")
      expect(page).to have_content("Subject to EIA")

      choose "Yes"

      expect(page).to have_content("Print the site notice")

      fill_in "Day", with: "1"
      fill_in "Month", with: "2"
      fill_in "Year", with: "2023"

      click_button "Create site notice", visible: true
      expect(page).to have_content("Site notice successfully created")
      expect(page).to have_link("Download site notice PDF", href: "#")

      expect(planning_application.site_notice.content).to include "This application is subject to an Environmental Impact Assessment (EIA)."
      expect(planning_application.site_notice.content).not_to include "View a hard copy of the Environment Statement"
    end

    it "contains the address and fee to get hard copy if included in EIA" do
      planning_application.environment_impact_assessment.update(address: "123 street", fee: 19, email_address: "planner@council.com")
      within :sidebar do
        click_link "Send site notice"
      end
      expect(page).to have_content("Send site notice")
      expect(page).to have_content("Subject to EIA")

      choose "Yes"

      expect(page).to have_content("Print the site notice")

      fill_in "Day", with: "1"
      fill_in "Month", with: "2"
      fill_in "Year", with: "2023"

      click_button "Create site notice", visible: true
      expect(page).to have_content("Site notice successfully created")
      expect(page).to have_link("Download site notice PDF", href: "#")

      expect(planning_application.site_notice.content).to include "This application is subject to an Environmental Impact Assessment (EIA)."
      expect(planning_application.site_notice.content).to include "You can request a hard copy for a fee of £19 by emailing planner@council.com or in person at 123 street."
    end
  end
end
