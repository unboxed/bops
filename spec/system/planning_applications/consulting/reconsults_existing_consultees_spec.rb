# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Consultation", js: true do
  let(:api_user) { create(:api_user, name: "PlanX") }
  let(:local_authority) { create(:local_authority, :default) }
  let(:assessor) { create(:user, :assessor, local_authority:) }
  let(:application_type) { create(:application_type, :planning_permission) }

  let(:planning_application) do
    create(
      :planning_application,
      :from_planx_prior_approval,
      :with_boundary_geojson,
      application_type:,
      local_authority:,
      api_user:,
      agent_email: "agent@example.com",
      applicant_email: "applicant@example.com",
      make_public: true
    )
  end

  let(:consultation) do
    planning_application.consultation
  end

  let(:notify_url) do
    "https://api.notifications.service.gov.uk/v2/notifications"
  end

  let(:today) do
    Date.current
  end

  let(:future) do
    Date.current + 14.days
  end

  let(:future_date) do
    future.to_fs
  end

  let(:current_date) do
    today.to_fs(:day_month_year_slashes)
  end

  let(:start_date) do
    consultation.start_date.to_fs(:day_month_year_slashes)
  end

  before do
    create(
      :consultee, :external,
      consultation: consultation,
      name: "Consultations",
      role: "Planning Department",
      organisation: "GLA",
      email_address: "planning@london.gov.uk",
      status: "awaiting_response",
      email_sent_at: 14.days.ago,
      email_delivered_at: 14.days.ago + 5.minutes
    )

    create(
      :consultee, :internal,
      consultation: consultation,
      name: "Chris Wood",
      role: "Tree Officer",
      organisation: local_authority.council_name,
      email_address: "chris.wood@#{local_authority.subdomain}.gov.uk",
      status: "awaiting_response",
      email_sent_at: 14.days.ago,
      email_delivered_at: 14.days.ago + 5.minutes
    )

    consultation.update(
      status: "in_progress",
      start_date: 14.days.ago,
      end_date: 7.days.from_now
    )
  end

  it "reconsults existing consultees" do
    sign_in assessor

    visit "/planning_applications/#{planning_application.id}"
    expect(page).to have_selector("h1", text: "Application")

    within "#consultation-section" do
      expect(page).to have_selector("li:first-child a", text: "Consultees, neighbours and publicity")
      expect(page).to have_selector("li:first-child .govuk-tag", text: "In progress")
    end

    click_link "Consultees, neighbours and publicity"
    expect(page).to have_selector("h1", text: "Consultation")

    within "#consultee-tasks" do
      expect(page).to have_selector("li:first-child a", text: "Send emails to consultees")
      expect(page).to have_selector("li:first-child .govuk-tag", text: "Awaiting responses")
    end

    click_link "Send emails to consultees"
    expect(page).to have_selector("h1", text: "Send emails to consultees")
    expect(page).to have_selector("h2", text: "1) Select the consultees to consult")
    expect(page).to have_selector("h2", text: "2) Send email to selected consultees")
    expect(page).to have_selector("h2", text: "3) Is this a reconsultation?")

    within "#external-consultees" do
      within "table tbody tr:first-child" do
        expect(page).to have_unchecked_field("Select consultee")
        expect(page).to have_selector("td:nth-child(2)", text: "Consultations")
        expect(page).to have_selector("td:nth-child(3)", text: "7 days")
        expect(page).to have_selector("td:nth-child(4)", text: start_date)
        expect(page).to have_selector("td:nth-child(5)", text: "Awaiting response")
      end
    end

    within "#internal-consultees" do
      within "table tbody tr:first-child" do
        expect(page).to have_unchecked_field("Select consultee")
        expect(page).to have_selector("td:nth-child(2)", text: "Chris Wood")
        expect(page).to have_selector("td:nth-child(3)", text: "7 days")
        expect(page).to have_selector("td:nth-child(4)", text: start_date)
        expect(page).to have_selector("td:nth-child(5)", text: "Awaiting response")
      end
    end

    accept_confirm(text: "Send emails to consultees?") do
      click_button "Send emails to consultees"
    end

    expect(page).to have_selector("[role=alert] li", text: "Please select at least one consultee")

    within "#external-consultees" do
      within "table tbody tr:first-child" do
        check "Select consultee"
      end
    end

    within "#resend-consultees" do
      choose "Yes, I’m reconsulting existing consultees"

      fill_in "Day", with: ""
      fill_in "Month", with: ""
      fill_in "Year", with: ""
    end

    accept_confirm(text: "Send emails to consultees?") do
      click_button "Send emails to consultees"
    end

    expect(page).to have_selector("[role=alert] li", text: "Please enter the reasons for the reconsultation")
    expect(page).to have_selector("[role=alert] li", text: "Please enter the date by which consultees need to respond by")

    within "#resend-consultees" do
      fill_in "Day", with: today.day
      fill_in "Month", with: today.month
      fill_in "Year", with: today.year
    end

    accept_confirm(text: "Send emails to consultees?") do
      click_button "Send emails to consultees"
    end

    expect(page).to have_selector("[role=alert] li", text: "Please enter a date in the future")

    within "#resend-consultees" do
      fill_in "Day", with: "50"
      fill_in "Month", with: today.month
      fill_in "Year", with: today.year
    end

    accept_confirm(text: "Send emails to consultees?") do
      click_button "Send emails to consultees"
    end

    expect(page).to have_selector("[role=alert] li", text: "Please enter a valid date")

    within "#resend-consultees" do
      fill_in "Reasons for reconsultation", with: "Application has changes - please respond by %<closing_date>s"
      fill_in "Day", with: future.day
      fill_in "Month", with: future.month
      fill_in "Year", with: future.year
    end

    expect do
      accept_confirm(text: "Send emails to consultees?") do
        click_button "Send emails to consultees"
      end

      expect(page).to have_selector("h1", text: "Consultation")
      expect(page).to have_selector("[role=alert] h3", text: "Emails have been sent to the selected consultees.")

      expect(Audit.where(
        planning_application_id: planning_application.id,
        user_id: assessor.id,
        activity_type: "consultees_reconsulted"
      )).to exist

      within "#consultee-tasks" do
        expect(page).to have_selector("li:first-child a", text: "Send emails to consultees")
        expect(page).to have_selector("li:first-child .govuk-tag", text: "Awaiting responses")
      end
    end.to have_enqueued_job(SendConsulteeEmailJob).exactly(:once)

    external = \
      stub_request(:post, "#{notify_url}/email")
        .with(body: hash_including(
          {
            email_address: "planning@london.gov.uk",
            email_reply_to_id: "4485df6f-a728-41ed-bc46-cdb2fc6789aa",
            personalisation: hash_including(
              "body" => a_string_starting_with("Application has changes - please respond by #{future_date}")
            )
          }
        ))
        .to_return(
          status: 200,
          headers: {
            "Content-Type" => "application/json"
          },
          body: {
            id: "48025d96-abc9-4b1d-a519-3cbc1c7f700b"
          }.to_json
        )

    perform_enqueued_jobs(at: Time.current)
    expect(external).to have_been_requested
    expect(consultation.reload.end_date).to eq(future.end_of_day.floor(6))
    expect(UpdateConsulteeEmailStatusJob).to have_been_enqueued.exactly(:once)

    click_link "Send emails to consultees"
    expect(page).to have_selector("h1", text: "Send emails to consultees")

    within "#external-consultees" do
      within "table tbody tr:first-child" do
        expect(page).to have_unchecked_field("Select consultee")
        expect(page).to have_selector("td:nth-child(2)", text: "Consultations")
        expect(page).to have_selector("td:nth-child(3)", text: "–")
        expect(page).to have_selector("td:nth-child(4)", text: "–")
        expect(page).to have_selector("td:nth-child(5)", text: "Sending")
      end
    end

    external_status = \
      stub_request(:get, "#{notify_url}/48025d96-abc9-4b1d-a519-3cbc1c7f700b")
        .to_return(
          status: 200,
          headers: {
            "Content-Type" => "application/json"
          },
          body: {
            status: "delivered"
          }.to_json
        )

    perform_enqueued_jobs
    expect(external_status).to have_been_requested

    click_link "Back"
    expect(page).to have_selector("h1", text: "Consultation")
    expect(page).to have_text("Consultation end date: #{future_date}")

    within "#consultee-tasks" do
      expect(page).to have_selector("li:first-child .govuk-tag", text: "Awaiting responses")
    end

    click_link "Send emails to consultees"
    expect(page).to have_selector("h1", text: "Send emails to consultees")

    within "#external-consultees" do
      within "table tbody tr:first-child" do
        expect(page).to have_unchecked_field("Select consultee")
        expect(page).to have_selector("td:nth-child(2)", text: "Consultations")
        expect(page).to have_selector("td:nth-child(3)", text: "21 days")
        expect(page).to have_selector("td:nth-child(4)", text: current_date)
        expect(page).to have_selector("td:nth-child(5)", text: "Awaiting response")
      end
    end

    within "#internal-consultees" do
      within "table tbody tr:first-child" do
        expect(page).to have_unchecked_field("Select consultee")
        expect(page).to have_selector("td:nth-child(2)", text: "Chris Wood")
        expect(page).to have_selector("td:nth-child(3)", text: "7 days")
        expect(page).to have_selector("td:nth-child(4)", text: start_date)
        expect(page).to have_selector("td:nth-child(5)", text: "Awaiting response")
      end
    end
  end
end
