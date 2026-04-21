# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Site notice task", js: true do
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

  let(:task) { planning_application.case_record.find_task_by_slug_path!("consultees-neighbours-and-publicity/publicity/site-notice") }

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

  describe "marking site notice as not required" do
    before do
      within :sidebar do
        click_link "Site notice"
      end
    end

    it "creates an audit and not required site notice" do
      expect(page).to have_content("No site notices have been created for this application")
      expect(task.reload).to be_not_started

      click_button "Mark as not required"

      expect(page).to have_content("Successfully marked site notice as not required")
      expect(planning_application.site_notices.count).to eq(1)
      expect(page).to have_content("Site notices are not required for this application")

      expect(planning_application.audits.where(activity_type: "site_notice_not_required").count).to eq(1)
      expect(task.reload).to be_completed
    end

    it "allows adding a site notice after marking as not required" do
      click_button "Mark as not required"
      expect(page).to have_content("Successfully marked site notice as not required")

      within :sidebar do
        click_link "Site notice"
      end

      expect(page).to have_content("Site notices are not required for this application")
      expect(planning_application.site_notices.required.count).to eq(0)

      click_link "Create site notice"

      fill_in "Quantity", with: "1"
      fill_in "Where should notices be displayed?", with: "Near main entrance"
      choose "Print the site notice"

      click_button "Send site notice"

      expect(page).to have_content("Successfully generated site notice")
      expect(planning_application.site_notices.required.count).to eq(1)
      expect(task.reload).to be_in_progress
    end
  end

  describe "adding a single site notice" do
    before do
      within :sidebar do
        click_link "Site notice"
      end

      click_link "Create site notice"

      fill_in "Quantity", with: "2"
      fill_in "Where should notices be displayed?", with: "Near the main entrance and rear gate"
      choose "Print the site notice"

      click_button "Send site notice"
    end

    it "shows the site notice in the table and puts the task in progress" do
      expect(page).to have_content("Successfully generated site notice")
      expect(page).to have_content("Site notice 1")

      within ".govuk-summary-card" do
        expect(page).to have_content("2")
        expect(page).to have_content("Near the main entrance and rear gate")
        expect(page).to have_selector("strong.govuk-tag", text: "Sent")
        expect(page).to have_link("Confirm display")
      end

      expect(task.reload).to be_in_progress
    end

    it "marks the task as complete" do
      click_button "Save and mark as complete"
      expect(page).to have_content("Successfully saved site notice task")
      expect(task.reload).to be_completed
    end

    describe "confirming display" do
      before do
        click_link "Confirm display"
      end

      it "shows errors when submitting without a date or evidence" do
        click_button "Confirm display"

        within ".govuk-error-summary" do
          expect(page).to have_content("Upload evidence of display")
          expect(page).to have_content("Displayed at")
        end
      end

      it "confirms display with date and evidence" do
        fill_in "Day", with: "10"
        fill_in "Month", with: "2"
        fill_in "Year", with: "2026"

        attach_file "2. Upload evidence of site notice in place", "spec/fixtures/files/images/existing-floorplan.png"

        click_button "Confirm display"

        expect(page).to have_content("Successfully saved display details")

        within ".govuk-summary-card" do
          expect(page).to have_selector("strong.govuk-tag--green", text: "Displayed")
          expect(page).to have_content("10 February 2026")
          expect(page).to have_link("Edit display details")
        end
      end
    end
  end

  describe "adding multiple site notices" do
    before do
      within :sidebar do
        click_link "Site notice"
      end

      click_link "Create site notice"
      fill_in "Quantity", with: "1"
      fill_in "Where should notices be displayed?", with: "Front entrance"
      choose "Print the site notice"
      click_button "Send site notice"
      expect(page).to have_content("Successfully generated site notice")

      click_link "Add another site notice"
      fill_in "Quantity", with: "3"
      fill_in "Where should notices be displayed?", with: "Rear gate and side entrance"
      choose "Print the site notice"
      click_button "Send site notice"
      expect(page).to have_content("Successfully generated site notice")
    end

    it "displays site notices in creation order" do
      cards = all(".govuk-summary-card")
      expect(cards.length).to eq(2)

      within(cards[0]) do
        expect(page).to have_content("Site notice 1")
        expect(page).to have_content("Front entrance")
        expect(page).to have_content("Sent")
      end

      within(cards[1]) do
        expect(page).to have_content("Site notice 2")
        expect(page).to have_content("Rear gate and side entrance")
      end
    end

    it "allows confirming display for each site notice" do
      within(all(".govuk-summary-card")[0]) do
        click_link "Confirm display"
      end

      fill_in "Day", with: "10"
      fill_in "Month", with: "3"
      fill_in "Year", with: "2026"
      attach_file "2. Upload evidence of site notice in place", "spec/fixtures/files/images/existing-floorplan.png"
      click_button "Confirm display"

      expect(page).to have_content("Successfully saved display details")

      cards = all(".govuk-summary-card")
      within(cards[0]) do
        expect(page).to have_selector("strong.govuk-tag--green", text: "Displayed")
      end
      within(cards[1]) do
        expect(page).to have_selector("strong.govuk-tag--blue", text: "Sent")
        click_link "Confirm display"
      end

      fill_in "Day", with: "15"
      fill_in "Month", with: "2"
      fill_in "Year", with: "2026"
      attach_file "2. Upload evidence of site notice in place", "spec/fixtures/files/images/existing-floorplan.png"
      click_button "Confirm display"

      expect(page).to have_content("Successfully saved display details")

      within(all(".govuk-summary-card")[1]) do
        expect(page).to have_selector("strong.govuk-tag--green", text: "Displayed")
      end
    end
  end
end
