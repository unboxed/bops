# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Consultation", type: :system, js: true do
  let(:api_user) { create(:api_user, :planx) }
  let(:local_authority) { create(:local_authority, :default) }
  let(:assessor) { create(:user, :assessor, local_authority:) }
  let(:application_type) { create(:application_type, :planning_permission) }

  let(:planning_application) do
    create(
      :planning_application,
      :from_planx_prior_approval,
      :with_boundary_geojson,
      :published,
      application_type:,
      local_authority:,
      api_user:,
      agent_email: "agent@example.com",
      applicant_email: "applicant@example.com"
    )
  end

  let(:consultation) do
    planning_application.consultation
  end

  let(:start_date) do
    consultation.start_date.to_date
  end

  let(:end_date) do
    consultation.end_date.to_date
  end

  let(:today) do
    Time.zone.today
  end

  let(:email_sent_at) do
    consultation.start_date
  end

  let(:email_delivered_at) do
    email_sent_at + 5.minutes
  end

  let(:expires_at) do
    consultation.end_date
  end

  before do
    consultation.update(
      status: "in_progress",
      start_date: 14.days.ago,
      end_date: 7.days.from_now
    )
  end

  context "when emails have been sent" do
    before do
      create(
        :consultee, :external,
        consultation: consultation,
        name: "Consultations",
        role: "Planning Department",
        organisation: "GLA",
        email_address: "planning@london.gov.uk",
        status: "awaiting_response",
        email_sent_at: email_sent_at,
        email_delivered_at: email_delivered_at,
        last_email_sent_at: email_sent_at,
        last_email_delivered_at: email_delivered_at,
        expires_at: expires_at
      )

      create(
        :consultee, :internal,
        consultation: consultation,
        name: "Chris Wood",
        role: "Tree Officer",
        organisation: local_authority.council_name,
        email_address: "chris.wood@#{local_authority.subdomain}.gov.uk",
        status: "awaiting_response",
        email_sent_at: email_sent_at,
        email_delivered_at: email_delivered_at,
        last_email_sent_at: email_sent_at,
        last_email_delivered_at: email_delivered_at,
        expires_at: expires_at
      )
    end

    it "allows consultee responses to be added and redacted" do
      sign_in assessor

      visit "/planning_applications/#{planning_application.reference}"
      expect(page).to have_selector("h1", text: "Application")

      within "#consultation-section" do
        expect(page).to have_selector("li:first-child a", text: "Consultees, neighbours and publicity")
        expect(page).to have_selector("li:first-child .govuk-tag", text: "In progress")
      end

      click_link "Consultees, neighbours and publicity"
      expect(page).to have_selector("h1", text: "Consultation")

      within "#consultation-end-date" do
        expect(page).to have_text("Consultation end #{end_date.to_date.to_fs(:day_month_year_slashes)}")
      end

      within "#consultee-tasks" do
        expect(page).to have_selector("li:nth-child(2) a", text: "Send emails to consultees")
        expect(page).to have_selector("li:nth-child(2) .govuk-tag", text: "Awaiting responses")
        expect(page).to have_selector("li:last-child a", text: "View consultee responses")
        expect(page).to have_selector("li:last-child .govuk-tag", text: "Not started")
      end

      click_link "View consultee responses"
      expect(page).to have_selector("h1", text: "View consultee responses")
      expect(page).to have_selector("h2", text: "Consultee overview")
      expect(page).to have_selector("h2", text: "External consultees (1)")
      expect(page).to have_selector("h2", text: "Internal consultees (1)")

      within "#consultee-overview" do
        within "table tbody tr:first-child" do
          expect(page).to have_selector("td:nth-child(1)", text: "Consultations Planning Department, GLA")
          expect(page).to have_selector("td:nth-child(2)", text: start_date.to_fs(:day_month_year_slashes))
          expect(page).to have_selector("td:nth-child(3)", text: end_date.to_fs(:day_month_year_slashes))
          expect(page).to have_selector("td:nth-child(4)", text: "Awaiting response")
        end

        within "table tbody tr:last-child" do
          expect(page).to have_selector("td:nth-child(1)", text: "Chris Wood Tree Officer, PlanX Council")
          expect(page).to have_selector("td:nth-child(2)", text: start_date.to_fs(:day_month_year_slashes))
          expect(page).to have_selector("td:nth-child(3)", text: end_date.to_fs(:day_month_year_slashes))
          expect(page).to have_selector("td:nth-child(4)", text: "Awaiting response")
        end
      end

      within "#external-consultee-responses" do
        within ".consultee-responses:first-of-type" do
          expect(page).to have_selector("h3", text: "Consultations (Planning Department, GLA)")
          expect(page).to have_selector("p time", text: "Last consulted on #{start_date.to_fs}")
          expect(page).to have_selector("p span", text: "Awaiting response")

          click_link "Upload new response"
        end
      end

      expect(page).to have_selector("h1", text: "Upload consultee response")
      expect(page).to have_selector("h2", text: "Add a new response")

      choose "Approved"
      fill_in "Response", with: "We are happy for this application to proceed"

      click_button "Save response"
      expect(page).to have_text("Response was successfully uploaded.")

      within "#consultee-overview" do
        within "table tbody tr:first-child" do
          expect(page).to have_selector("td:nth-child(1)", text: "Consultations Planning Department, GLA")
          expect(page).to have_selector("td:nth-child(2)", text: start_date.to_fs(:day_month_year_slashes))
          expect(page).to have_selector("td:nth-child(3)", text: end_date.to_fs(:day_month_year_slashes))
          expect(page).to have_selector("td:nth-child(4)", text: "Approved")
        end
      end

      within "#external-consultee-responses" do
        within ".consultee-responses:first-of-type" do
          expect(page).to have_selector("h3", text: "Consultations (Planning Department, GLA)")
          expect(page).to have_selector("p time", text: "Last received on #{today.to_fs}")
          expect(page).to have_selector("p span", text: "Approved")
          expect(page).to have_selector("p", text: "We are happy for this application to proceed")

          click_link "View all responses (1)"
        end
      end

      expect(page).to have_selector("h1", text: "View consultee response")

      within "#consultee-summary" do
        expect(page).to have_selector("h2", text: "Consultee")

        within ".govuk-summary-list__row:nth-of-type(1)" do
          expect(page).to have_selector("dt", text: "Name")
          expect(page).to have_selector("dd", text: "Consultations")
        end

        within ".govuk-summary-list__row:nth-of-type(2)" do
          expect(page).to have_selector("dt", text: "Role")
          expect(page).to have_selector("dd", text: "Planning Department")
        end

        within ".govuk-summary-list__row:nth-of-type(3)" do
          expect(page).to have_selector("dt", text: "Organisation")
          expect(page).to have_selector("dd", text: "GLA")
        end

        within ".govuk-summary-list__row:nth-of-type(4)" do
          expect(page).to have_selector("dt", text: "Email address")
          expect(page).to have_selector("dd", text: "planning@london.gov.uk")
        end

        within ".govuk-summary-list__row:nth-of-type(5)" do
          expect(page).to have_selector("dt", text: "Consulted on")
          expect(page).to have_selector("dd", text: start_date.to_fs)
        end

        within ".govuk-summary-list__row:nth-of-type(6)" do
          expect(page).to have_selector("dt", text: "Last received on")
          expect(page).to have_selector("dd", text: today.to_fs)
        end

        within ".govuk-summary-list__row:nth-of-type(7)" do
          expect(page).to have_selector("dt", text: "Status")
          expect(page).to have_selector("dd", text: "Approved")
        end
      end

      within "#consultee-responses" do
        expect(page).to have_selector("h2", text: "Responses")

        within ".consultee-response:first-of-type" do
          expect(page).to have_selector("p time", text: "Received on #{today.to_fs}")
          expect(page).to have_selector("p span", text: "Approved")
          expect(page).to have_selector("p span", text: "Private")
          expect(page).to have_selector("p", text: "We are happy for this application to proceed")

          click_link "Redact and publish"
        end
      end

      expect(page).to have_selector("h1", text: "Redact comment")

      click_button "Reset comment"
      expect(page).to have_field("Redacted comment", with: "We are happy for this application to proceed")

      click_button "Save and publish"
      expect(page).to have_text("Response was successfully published.")

      within "#consultee-responses" do
        within ".consultee-response:first-of-type" do
          expect(page).to have_selector("p span", text: "Published")
        end
      end

      click_link "Back"
      expect(page).to have_selector("h1", text: "View consultee responses")

      click_link "Back"
      expect(page).to have_selector("h1", text: "Consultation")

      within "#consultee-tasks" do
        expect(page).to have_selector("li:last-child a", text: "View consultee responses")
        expect(page).to have_selector("li:last-child .govuk-tag", text: "In progress")
      end
    end
  end

  context "when emails have not been sent" do
    before do
      create(
        :consultee, :external,
        consultation: consultation,
        name: "Consultations",
        role: "Planning Department",
        organisation: "GLA",
        email_address: "planning@london.gov.uk",
        status: "not_consulted",
        email_sent_at: nil,
        email_delivered_at: nil,
        last_email_sent_at: nil,
        last_email_delivered_at: nil,
        expires_at: nil
      )

      create(
        :consultee, :internal,
        consultation: consultation,
        name: "Chris Wood",
        role: "Tree Officer",
        organisation: local_authority.council_name,
        email_address: "chris.wood@#{local_authority.subdomain}.gov.uk",
        status: "not_consulted",
        email_sent_at: nil,
        email_delivered_at: nil,
        last_email_sent_at: nil,
        last_email_delivered_at: nil,
        expires_at: nil
      )
    end

    it "allows consultee responses to be added and redacted" do
      sign_in assessor

      visit "/planning_applications/#{planning_application.reference}"
      expect(page).to have_selector("h1", text: "Application")

      within "#consultation-section" do
        expect(page).to have_selector("li:first-child a", text: "Consultees, neighbours and publicity")
        expect(page).to have_selector("li:first-child .govuk-tag", text: "In progress")
      end

      click_link "Consultees, neighbours and publicity"
      expect(page).to have_selector("h1", text: "Consultation")

      within "#consultation-end-date" do
        expect(page).to have_text("Consultation end #{end_date.to_date.to_fs(:day_month_year_slashes)}")
      end

      within "#consultee-tasks" do
        expect(page).to have_selector("li:nth-child(2) a", text: "Send emails to consultees")
        expect(page).to have_selector("li:nth-child(2) .govuk-tag", text: "In progress")
        expect(page).to have_selector("li:last-child a", text: "View consultee responses")
        expect(page).to have_selector("li:last-child .govuk-tag", text: "Not started")
      end

      click_link "View consultee responses"
      expect(page).to have_selector("h1", text: "View consultee responses")
      expect(page).to have_selector("h2", text: "Consultee overview")
      expect(page).to have_selector("h2", text: "External consultees (1)")
      expect(page).to have_selector("h2", text: "Internal consultees (1)")

      within "#consultee-overview" do
        within "table tbody tr:first-child" do
          expect(page).to have_selector("td:nth-child(1)", text: "Consultations Planning Department, GLA")
          expect(page).to have_selector("td:nth-child(2)", text: "–")
          expect(page).to have_selector("td:nth-child(3)", text: "–")
          expect(page).to have_selector("td:nth-child(4)", text: "Not consulted")
        end

        within "table tbody tr:last-child" do
          expect(page).to have_selector("td:nth-child(1)", text: "Chris Wood Tree Officer, PlanX Council")
          expect(page).to have_selector("td:nth-child(2)", text: "–")
          expect(page).to have_selector("td:nth-child(3)", text: "–")
          expect(page).to have_selector("td:nth-child(4)", text: "Not consulted")
        end
      end

      within "#external-consultee-responses" do
        within ".consultee-responses:first-of-type" do
          expect(page).to have_selector("h3", text: "Consultations (Planning Department, GLA)")
          expect(page).not_to have_selector("p time")
          expect(page).to have_selector("p span", text: "Not consulted")

          click_link "Upload new response"
        end
      end

      expect(page).to have_selector("h1", text: "Upload consultee response")
      expect(page).to have_selector("h2", text: "Add a new response")

      choose "Approved"
      fill_in "Response", with: "We are happy for this application to proceed"
      attach_file("Upload documents", "spec/fixtures/files/images/proposed-floorplan.png")

      click_button "Save response"
      expect(page).to have_text("Response was successfully uploaded.")

      within "#consultee-overview" do
        within "table tbody tr:first-child" do
          expect(page).to have_selector("td:nth-child(1)", text: "Consultations Planning Department, GLA")
          expect(page).to have_selector("td:nth-child(2)", text: "–")
          expect(page).to have_selector("td:nth-child(3)", text: "–")
          expect(page).to have_selector("td:nth-child(4)", text: "Approved")
        end
      end

      within "#external-consultee-responses" do
        within ".consultee-responses:first-of-type" do
          expect(page).to have_selector("h3", text: "Consultations (Planning Department, GLA)")
          expect(page).to have_selector("p time", text: "Last received on #{today.to_fs}")
          expect(page).to have_selector("p span", text: "Approved")
          expect(page).to have_selector("p", text: "We are happy for this application to proceed")

          click_link "View all responses (1)"
        end
      end

      expect(page).to have_selector("h1", text: "View consultee response")

      within "#consultee-summary" do
        expect(page).to have_selector("h2", text: "Consultee")

        within ".govuk-summary-list__row:nth-of-type(1)" do
          expect(page).to have_selector("dt", text: "Name")
          expect(page).to have_selector("dd", text: "Consultations")
        end

        within ".govuk-summary-list__row:nth-of-type(2)" do
          expect(page).to have_selector("dt", text: "Role")
          expect(page).to have_selector("dd", text: "Planning Department")
        end

        within ".govuk-summary-list__row:nth-of-type(3)" do
          expect(page).to have_selector("dt", text: "Organisation")
          expect(page).to have_selector("dd", text: "GLA")
        end

        within ".govuk-summary-list__row:nth-of-type(4)" do
          expect(page).to have_selector("dt", text: "Email address")
          expect(page).to have_selector("dd", text: "planning@london.gov.uk")
        end

        within ".govuk-summary-list__row:nth-of-type(5)" do
          expect(page).to have_selector("dt", text: "Consulted on")
          expect(page).to have_selector("dd", text: "–")
        end

        within ".govuk-summary-list__row:nth-of-type(6)" do
          expect(page).to have_selector("dt", text: "Last received on")
          expect(page).to have_selector("dd", text: today.to_fs)
        end

        within ".govuk-summary-list__row:nth-of-type(7)" do
          expect(page).to have_selector("dt", text: "Status")
          expect(page).to have_selector("dd", text: "Approved")
        end
      end

      within "#consultee-responses" do
        expect(page).to have_selector("h2", text: "Responses")

        within ".consultee-response:first-of-type" do
          expect(page).to have_selector("p time", text: "Received on #{today.to_fs}")
          expect(page).to have_selector("p span", text: "Approved")
          expect(page).to have_selector("p span", text: "Private")
          expect(page).to have_selector("p", text: "We are happy for this application to proceed")

          click_link "Redact and publish"
        end
      end

      expect(page).to have_selector("h1", text: "Redact comment")

      click_button "Reset comment"
      expect(page).to have_field("Redacted comment", with: "We are happy for this application to proceed")

      click_button "Save and publish"
      expect(page).to have_text("Response was successfully published.")

      within "#consultee-responses" do
        within ".consultee-response:first-of-type" do
          expect(page).to have_selector("p span", text: "Published")
        end
      end

      click_link "Back"
      expect(page).to have_selector("h1", text: "View consultee responses")

      click_link "Back"
      expect(page).to have_selector("h1", text: "Consultation")

      within "#consultee-tasks" do
        expect(page).to have_selector("li:last-child a", text: "View consultee responses")
        expect(page).to have_selector("li:last-child .govuk-tag", text: "In progress")
      end

      visit "/planning_applications/#{planning_application.reference}/documents"
      expect(page).to_not have_content("proposed-floorplan.png")
    end
  end
end
