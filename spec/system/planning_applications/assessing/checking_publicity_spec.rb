# frozen_string_literal: true

require "rails_helper"

RSpec.describe "checking publicity" do
  let!(:local_authority) { create(:local_authority, :default, press_notice_email: "pressnotices@example.com") }

  let!(:assessor) do
    create(:user, :assessor, name: "Alice Smith", local_authority: local_authority)
  end

  let!(:uploader) do
    create(:user, :assessor, name: "Bob Jones", local_authority: local_authority)
  end

  let!(:planning_application) do
    create(:planning_application, :in_assessment, :planning_permission, local_authority: local_authority)
  end

  let!(:consultation) do
    planning_application.consultation
  end

  around do |example|
    travel_to("2024-02-29T14:00:00Z") do
      example.run
    end
  end

  before do
    sign_in assessor
  end

  context "when the publicity has been confirmed correctly" do
    let!(:site_notice) do
      create(:site_notice,
        planning_application: planning_application,
        required: true,
        displayed_at: "2024-01-08T09:00:00Z",
        expiry_date: "2024-01-30",
        internal_team_email: "pressteam@example.com")
    end

    let!(:press_notice) do
      create(:press_notice,
        planning_application: planning_application,
        required: true,
        reasons: ["major_development"],
        requested_at: "2024-01-08T09:00:00Z",
        published_at: "2024-01-11T09:00:00Z",
        expiry_date: "2024-02-01")
    end

    let!(:site_notice_evidence) do
      create(:document,
        planning_application: planning_application,
        owner: site_notice,
        user: uploader,
        file: fixture_file_upload("site-notice.jpg", "image/jpeg", true),
        tags: ["internal.siteNotice"])
    end

    let!(:press_notice_evidence) do
      create(:document,
        planning_application: planning_application,
        owner: press_notice,
        user: uploader,
        file: fixture_file_upload("press-notice.jpg", "image/jpeg", true),
        tags: ["internal.pressNotice"])
    end

    it "allows an assessor to mark the publicity check as complete" do
      visit "/planning_applications/#{planning_application.id}/assessment/tasks"

      expect(page).to have_selector("h1", text: "Assess the application")
      expect(page).to have_link("Check site notice and press notice", href: "/planning_applications/#{planning_application.id}/assessment/assessment_details/new?category=check_publicity")

      click_link "Check site notice and press notice"

      expect(page).to have_selector("h1", text: "Check site notice and press notice")

      within("#site-notice-check") do
        expect(page).to have_selector("h2", text: "Check site notice")

        within "tbody tr:nth-child(1)" do
          expect(page).to have_selector("td:nth-child(1)", text: "08/01/2024")
          expect(page).to have_selector("td:nth-child(2)", text: "Bob Jones")
          expect(page).to have_selector("td:nth-child(3)", text: "30/01/2024")
        end

        expect(page).to have_selector("a", text: "View in new window")
        expect(page).to have_selector("a", text: "View more documents")

        expect(page).to have_content("File name: site-notice.jpg")
        expect(page).to have_content("Date uploaded: 29 February 2024")
      end

      within("#press-notice-check") do
        expect(page).to have_selector("h2", text: "Check press notice")

        within "tbody tr:nth-child(1)" do
          expect(page).to have_selector("td:nth-child(1)", text: "Major development")
          expect(page).to have_selector("td:nth-child(2)", text: "11/01/2024")
          expect(page).to have_selector("td:nth-child(3)", text: "Bob Jones")
          expect(page).to have_selector("td:nth-child(4)", text: "01/02/2024")
        end

        expect(page).to have_selector("a", text: "View in new window")
        expect(page).to have_selector("a", text: "View more documents")

        expect(page).to have_content("File name: press-notice.jpg")
        expect(page).to have_content("Date uploaded: 29 February 2024")
      end

      click_button "Save and mark as complete"

      expect(page).to have_selector("h1", text: "Assess the application")
      expect(page).to have_selector("[role=alert] p", text: "Publicity check was successfully created.")
    end
  end

  context "when the publicity has not been started" do
    it "shows an alert to create a site notice" do
      visit "/planning_applications/#{planning_application.id}/assessment/tasks"

      expect(page).to have_selector("h1", text: "Assess the application")
      expect(page).to have_link("Check site notice and press notice", href: "/planning_applications/#{planning_application.id}/assessment/assessment_details/new?category=check_publicity")

      click_link "Check site notice and press notice"
      expect(page).to have_selector("h1", text: "Check site notice and press notice")

      within "[role=alert]" do
        expect(page).to have_selector("p", text: "Site notice task incomplete.")
        expect(page).to have_link("Create site notice", href: "/planning_applications/#{planning_application.id}/site_notices/new")
      end
    end

    it "shows an alert to create a press notice" do
      visit "/planning_applications/#{planning_application.id}/assessment/tasks"

      expect(page).to have_selector("h1", text: "Assess the application")
      expect(page).to have_link("Check site notice and press notice", href: "/planning_applications/#{planning_application.id}/assessment/assessment_details/new?category=check_publicity")

      click_link "Check site notice and press notice"
      expect(page).to have_selector("h1", text: "Check site notice and press notice")

      within "[role=alert]" do
        expect(page).to have_selector("p", text: "Press notice task incomplete.")
        expect(page).to have_link("Create press notice", href: "/planning_applications/#{planning_application.id}/press_notice")
      end
    end
  end

  context "when the publicity has not been confirmed" do
    let!(:site_notice) do
      create(:site_notice,
        planning_application: planning_application,
        required: true,
        displayed_at: nil,
        expiry_date: nil,
        internal_team_email: "sitenotices@example.com")
    end

    let!(:press_notice) do
      create(:press_notice,
        planning_application: planning_application,
        required: true,
        reasons: ["major_development"],
        requested_at: "2024-01-08T09:00:00Z",
        published_at: nil,
        expiry_date: nil)
    end

    before do
      visit "/planning_applications/#{planning_application.id}/assessment/tasks"

      expect(page).to have_selector("h1", text: "Assess the application")
      expect(page).to have_link("Check site notice and press notice", href: "/planning_applications/#{planning_application.id}/assessment/assessment_details/new?category=check_publicity")

      click_link "Check site notice and press notice"
      expect(page).to have_selector("h1", text: "Check site notice and press notice")
    end

    it "shows an alert to confirm the site notice" do
      within "[role=alert]" do
        expect(page).to have_selector("p", text: "Site notice task incomplete.")
        expect(page).to have_link("Confirm site notice", href: "/planning_applications/#{planning_application.id}/site_notices/#{site_notice.id}/edit")
      end
    end

    it "shows an alert to confirm the press notice" do
      within "[role=alert]" do
        expect(page).to have_selector("p", text: "Press notice task incomplete.")
        expect(page).to have_link("Confirm press notice", href: "/planning_applications/#{planning_application.id}/press_notice/confirmation")
      end
    end

    it "allows a confirmation request to be sent for the site notice" do
      within("#site-notice-check") do
        within "tbody tr:nth-child(1)" do
          expect(page).to have_selector("td:nth-child(1)", text: "–")
          expect(page).to have_selector("td:nth-child(2)", text: "–")
          expect(page).to have_selector("td:nth-child(3)", text: "–")
        end

        expect(page).to have_selector("p", text: "No documents uploaded")
        expect(page).to have_selector("a", text: "Upload evidence")
      end

      expect do
        click_button "Request document from internal team"
        expect(page).to have_selector("[role=alert] p", text: "Request for confirmation of the site notice sent to the internal team")
      end.to have_enqueued_job(SendSiteNoticeConfirmationRequestJob).exactly(:once)

      perform_enqueued_jobs

      expect(last_email_sent).to deliver_to("sitenotices@example.com")
      expect(last_email_sent).to have_subject("Request for confirmation of a site notice for #{planning_application.reference}")
      expect(last_email_sent).to have_body_text("Please use this link to upload evidence of a site notice in place for this application")
    end

    it "allows a confirmation request to be sent for the press notice" do
      within("#press-notice-check") do
        within "tbody tr:nth-child(1)" do
          expect(page).to have_selector("td:nth-child(1)", text: "Major development")
          expect(page).to have_selector("td:nth-child(2)", text: "–")
          expect(page).to have_selector("td:nth-child(3)", text: "–")
          expect(page).to have_selector("td:nth-child(4)", text: "–")
        end

        expect(page).to have_selector("p", text: "No documents uploaded")
        expect(page).to have_selector("a", text: "Upload evidence")
      end

      expect do
        click_button "Request new document"
        expect(page).to have_selector("[role=alert] p", text: "Request for confirmation of the press notice sent to the press team")
      end.to have_enqueued_job(SendPressNoticeConfirmationRequestJob).exactly(:once)

      perform_enqueued_jobs

      expect(last_email_sent).to deliver_to("pressnotices@example.com")
      expect(last_email_sent).to have_subject("Request for confirmation of a press notice for #{planning_application.reference}")
      expect(last_email_sent).to have_body_text("Please use this link to upload evidence of a press notice for this application")
    end
  end

  context "when the publicity has not been confirmed and there are no contact details" do
    let!(:local_authority) { create(:local_authority, :default, press_notice_email: "") }

    let!(:site_notice) do
      create(:site_notice,
        planning_application: planning_application,
        required: true,
        displayed_at: nil,
        expiry_date: nil,
        internal_team_email: "")
    end

    let!(:press_notice) do
      create(:press_notice,
        planning_application: planning_application,
        required: true,
        reasons: ["major_development"],
        requested_at: "2024-01-08T09:00:00Z",
        published_at: nil,
        expiry_date: nil)
    end

    before do
      visit "/planning_applications/#{planning_application.id}/assessment/tasks"

      expect(page).to have_selector("h1", text: "Assess the application")
      expect(page).to have_link("Check site notice and press notice", href: "/planning_applications/#{planning_application.id}/assessment/assessment_details/new?category=check_publicity")

      click_link "Check site notice and press notice"
      expect(page).to have_selector("h1", text: "Check site notice and press notice")
    end

    it "doesn't allow a confirmation request to be sent for the site notice" do
      within("#site-notice-check") do
        expect(page).not_to have_button("Request document from internal team")
      end
    end

    it "allows a confirmation request to be sent for the press notice" do
      within("#press-notice-check") do
        expect(page).not_to have_button("Request new document")
      end
    end
  end

  context "when the publicity has already been checked" do
    let!(:site_notice) do
      create(:site_notice,
        planning_application: planning_application,
        required: true,
        displayed_at: "2024-01-08T09:00:00Z",
        expiry_date: "2024-01-30",
        internal_team_email: "pressteam@example.com")
    end

    let!(:press_notice) do
      create(:press_notice,
        planning_application: planning_application,
        required: true,
        reasons: ["major_development"],
        requested_at: "2024-01-08T09:00:00Z",
        published_at: "2024-01-11T09:00:00Z",
        expiry_date: "2024-02-01")
    end

    let!(:site_notice_evidence) do
      create(:document,
        planning_application: planning_application,
        owner: site_notice,
        user: uploader,
        file: fixture_file_upload("site-notice.jpg", "image/jpeg", true),
        tags: ["internal.siteNotice"])
    end

    let!(:press_notice_evidence) do
      create(:document,
        planning_application: planning_application,
        owner: press_notice,
        user: uploader,
        file: fixture_file_upload("press-notice.jpg", "image/jpeg", true),
        tags: ["internal.pressNotice"])
    end

    let!(:assessment_detail) do
      create(:assessment_detail,
        planning_application: planning_application,
        user: assessor,
        assessment_status: "complete",
        category: "check_publicity")
    end

    it "allows editing of the publicity check" do
      visit "/planning_applications/#{planning_application.id}/assessment/tasks"

      expect(page).to have_selector("h1", text: "Assess the application")
      expect(page).to have_link("Check site notice and press notice", href: "/planning_applications/#{planning_application.id}/assessment/assessment_details/#{assessment_detail.id}?category=check_publicity")

      click_link "Check site notice and press notice"
      expect(page).to have_selector("h1", text: "Site notice and press notice")

      within("#site-notice") do
        expect(page).to have_selector("h2", text: "Site notice")

        within "tbody tr:nth-child(1)" do
          expect(page).to have_selector("td:nth-child(1)", text: "08/01/2024")
          expect(page).to have_selector("td:nth-child(2)", text: "Bob Jones")
          expect(page).to have_selector("td:nth-child(3)", text: "30/01/2024")
        end

        expect(page).to have_selector("a", text: "View in new window")
        expect(page).to have_selector("a", text: "View more documents")

        expect(page).to have_content("File name: site-notice.jpg")
        expect(page).to have_content("Date uploaded: 29 February 2024")
      end

      within("#press-notice") do
        expect(page).to have_selector("h2", text: "Press notice")

        within "tbody tr:nth-child(1)" do
          expect(page).to have_selector("td:nth-child(1)", text: "Major development")
          expect(page).to have_selector("td:nth-child(2)", text: "11/01/2024")
          expect(page).to have_selector("td:nth-child(3)", text: "Bob Jones")
          expect(page).to have_selector("td:nth-child(4)", text: "01/02/2024")
        end

        expect(page).to have_selector("a", text: "View in new window")
        expect(page).to have_selector("a", text: "View more documents")

        expect(page).to have_content("File name: press-notice.jpg")
        expect(page).to have_content("Date uploaded: 29 February 2024")
      end

      click_link "Edit site notice and press notice check"
      expect(page).to have_selector("h1", text: "Check site notice and press notice")

      click_button "Save and come back later"
      expect(page).to have_selector("h1", text: "Assess the application")
      expect(page).to have_selector("[role=alert] p", text: "Publicity check was successfully updated.")

      within("#check-consistency-assessment-tasks") do
        within("li:nth-child(2)") do
          expect(page).to have_link("Check site notice and press notice", href: "/planning_applications/#{planning_application.id}/assessment/assessment_details/#{assessment_detail.id}/edit?category=check_publicity")
          expect(page).to have_selector("strong", text: "In progress")
        end
      end
    end
  end
end
