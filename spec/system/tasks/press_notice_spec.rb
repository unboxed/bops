# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Press notice task", js: true do
  let(:default_local_authority) { create(:local_authority, :default, press_notice_email: "pressnotice@example.com") }
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

  let(:task) do
    planning_application.case_record.find_task_by_slug_path!(
      "consultees-neighbours-and-publicity/publicity/press-notice"
    )
  end

  around do |example|
    travel_to("2026-02-01") { example.run }
  end

  before do
    sign_in(assessor)
    visit "/planning_applications/#{planning_application.reference}"
    click_link "Consultees, neighbours and publicity"
  end

  describe "marking press notice as not required" do
    before do
      within :sidebar do
        click_link "Press notice"
      end
    end

    it "creates no press notices and marks the task as complete" do
      expect(page).to have_content("No press notices have been created for this application")
      expect(task.reload).to be_not_started

      click_button "Mark as not required"

      expect(page).to have_content("Successfully saved press notice requirement")
      expect(planning_application.press_notices.where(required: false).count).to eq(1)
      expect(page).to have_content("Press notices are not required for this application")
      expect(task.reload).to be_completed
    end

    it "allows creating a press notice after marking as not required, showing the table" do
      click_button "Mark as not required"

      expect(page).to have_content("Press notices are not required for this application")

      click_link "Create press notice"

      check "The application is for a Major Development"
      click_button "Send request"

      expect(page).to have_content("Successfully sent press notice email")
      expect(planning_application.press_notices.where(required: true).count).to eq(1)

      within ".govuk-summary-card" do
        expect(page).to have_content("Press notice 1")
        expect(page).to have_selector("strong.govuk-tag--blue", text: "Requested")
      end

      expect(task.reload).to be_in_progress
    end
  end

  describe "adding a single press notice" do
    before do
      within :sidebar do
        click_link "Press notice"
      end

      click_link "Create press notice"
    end

    it "shows a validation error when no reasons are selected" do
      click_button "Send request"

      within ".govuk-error-summary" do
        expect(page).to have_content("Select a reason for the press notice")
      end
    end

    it "shows the press notice in the table with all fields and puts the task in progress" do
      check "The application is for a Major Development"
      check "An environmental statement accompanies this application"

      click_button "Send request"

      expect(page).to have_content("Successfully sent press notice email")
      expect(task.reload).to be_in_progress

      within ".govuk-summary-card" do
        expect(page).to have_content("Press notice 1")

        expect(page).to have_css("li", text: "The application is for a Major Development")
        expect(page).to have_css("li", text: "An environmental statement accompanies this application")

        expect(page).to have_content("pressnotice@example.com")
        expect(page).to have_selector("strong.govuk-tag--blue", text: "Requested")
        expect(page).to have_link("Upload evidence")
      end
    end

    it "shows the requested date in the table after the email job runs" do
      check "The application is for a Major Development"
      click_button "Send request"

      expect(page).to have_content("Successfully sent press notice email")

      perform_enqueued_jobs

      visit "/planning_applications/#{planning_application.reference}/consultees-neighbours-and-publicity/publicity/press-notice"

      within ".govuk-summary-card" do
        expect(page).to have_content("1 February 2026 00:00")
      end
    end

    it "marks the task as complete" do
      check "The application is for a Major Development"
      click_button "Send request"

      expect(page).to have_content("Successfully sent press notice email")

      click_button "Save and mark as complete"

      expect(page).to have_content("Successfully saved press notice requirement")
      expect(task.reload).to be_completed
    end
  end

  describe "adding multiple press notices" do
    # Use factories with different created_at values to ensure deterministic ordering
    let!(:older_press_notice) do
      create(:press_notice,
        planning_application:,
        required: true,
        reasons: %w[major_development],
        requested_at: Time.zone.now,
        created_at: 2.hours.ago)
    end
    let!(:newer_press_notice) do
      create(:press_notice,
        planning_application:,
        required: true,
        reasons: %w[environment],
        requested_at: Time.zone.now,
        created_at: 1.hour.ago)
    end

    before do
      within :sidebar do
        click_link "Press notice"
      end
    end

    it "displays press notices with the most recently created first" do
      cards = all(".govuk-summary-card")
      expect(cards.length).to eq(2)

      within(cards[0]) do
        expect(page).to have_content("Press notice 1")
        expect(page).to have_css("li", text: "An environmental statement accompanies this application")
      end

      within(cards[1]) do
        expect(page).to have_content("Press notice 2")
        expect(page).to have_css("li", text: "The application is for a Major Development")
      end
    end
  end

  describe "editing a press notice" do
    before do
      planning_application.consultation.update!(
        start_date: Date.new(2026, 1, 15),
        end_date: Date.new(2026, 2, 28)
      )

      within :sidebar do
        click_link "Press notice"
      end

      click_link "Create press notice"
      check "The application is for a Major Development"
      click_button "Send request"

      expect(page).to have_content("Successfully sent press notice email")

      within ".govuk-summary-card" do
        click_link "Upload evidence"
      end
    end

    it "shows a validation error when no published date is given" do
      click_button "Confirm publication"

      within ".govuk-error-summary" do
        expect(page).to have_content("Please select when press notice was published")
      end
    end

    it "confirms publication with a date and document" do
      fill_in "Day", with: "20"
      fill_in "Month", with: "1"
      fill_in "Year", with: "2026"

      attach_file "Upload evidence of publication", "spec/fixtures/files/images/existing-floorplan.png"

      click_button "Confirm publication"

      expect(page).to have_content("Successfully saved press notice requirement")

      within ".govuk-summary-card" do
        expect(page).to have_selector("strong.govuk-tag--green", text: "Displayed")
        expect(page).to have_content("Published: 20 January 2026")
        expect(page).to have_link("Edit publication details")
        expect(page).not_to have_link("Upload evidence")
      end
    end

    it "allows editing publication details after initial confirmation" do
      fill_in "Day", with: "20"
      fill_in "Month", with: "1"
      fill_in "Year", with: "2026"
      attach_file "Upload evidence of publication", "spec/fixtures/files/images/existing-floorplan.png"
      click_button "Confirm publication"

      expect(page).to have_content("Successfully saved press notice requirement")

      within ".govuk-summary-card" do
        click_link "Edit publication details"
      end

      fill_in "Day", with: "25"
      fill_in "Month", with: "1"
      fill_in "Year", with: "2026"
      click_button "Confirm publication"

      expect(page).to have_content("Successfully saved press notice requirement")

      within ".govuk-summary-card" do
        expect(page).to have_content("Published: 25 January 2026")
      end
    end
  end

  describe "marking press notice as published" do
    before do
      planning_application.consultation.update!(
        start_date: Date.new(2026, 1, 15),
        end_date: Date.new(2026, 2, 28)
      )

      within :sidebar do
        click_link "Press notice"
      end

      click_link "Create press notice"
      check "The application is for a Major Development"
      click_button "Send request"

      expect(page).to have_content("Successfully sent press notice email")
    end

    it "shows Requested status before publication then Displayed with evidence details after" do
      within ".govuk-summary-card" do
        expect(page).to have_selector("strong.govuk-tag--blue", text: "Requested")
        expect(page).not_to have_selector("strong.govuk-tag--green")
        click_link "Upload evidence"
      end

      fill_in "Day", with: "25"
      fill_in "Month", with: "1"
      fill_in "Year", with: "2026"
      fill_in "Comment (optional)", with: "Published in the local gazette, page 5"
      attach_file "Upload evidence of publication", "spec/fixtures/files/images/existing-floorplan.png"
      click_button "Confirm publication"

      expect(page).to have_content("Successfully saved press notice requirement")

      within ".govuk-summary-card" do
        expect(page).to have_selector("strong.govuk-tag--green", text: "Displayed")
        expect(page).not_to have_selector("strong.govuk-tag--blue")
        expect(page).to have_content("Published: 25 January 2026")
        expect(page).to have_content("Published in the local gazette, page 5")
        expect(page).to have_link("Edit publication details")
        expect(page).not_to have_link("Upload evidence")
      end
    end
  end
end
