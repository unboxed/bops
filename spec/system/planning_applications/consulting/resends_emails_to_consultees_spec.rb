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

  let(:notify_url) do
    "https://api.notifications.service.gov.uk/v2/notifications"
  end

  let(:today) do
    Date.current
  end

  let(:end_date) do
    Date.current + 7.days
  end

  let(:current_date) do
    today.to_fs(:day_month_year_slashes)
  end

  let(:start) do
    consultation.start_date
  end

  let(:start_date) do
    start.to_fs(:day_month_year_slashes)
  end

  let(:existing_date) do
    consultation.end_date.to_date.to_fs
  end

  let(:email_sent_at) do
    14.days.ago
  end

  let(:email_delivered_at) do
    email_sent_at + 5.minutes
  end

  let(:expires_at) do
    7.days.from_now.end_of_day
  end

  let(:now) do
    Time.current
  end

  let(:consultee_response_date) do
    (today + 5.days).to_fs
  end

  let(:consultee) do
    Consultee.find_by!(email_address: "planning@london.gov.uk")
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

    consultation.update(
      status: "in_progress",
      start_date: 14.days.ago,
      end_date: 7.days.from_now
    )
  end

  it "resends emails to existing consultees" do
    sign_in assessor

    visit "/planning_applications/#{planning_application.reference}"
    expect(page).to have_selector("h1", text: "Application")

    within "#consultation-section" do
      expect(page).to have_selector("li:first-child a", text: "Consultees, neighbours and publicity")
      expect(page).to have_selector("li:first-child .govuk-tag", text: "In progress")
    end

    click_link "Consultees, neighbours and publicity"
    expect(page).to have_selector("h1", text: "Consultation")

    within("#consultation-end-date") do
      expect(page).to have_text("Consultation end #{end_date.to_fs(:day_month_year_slashes)}")
    end

    within "#consultee-tasks" do
      expect(page).to have_selector("li:nth-child(2) a", text: "Send emails to consultees")
      expect(page).to have_selector("li:nth-child(2) .govuk-tag", text: "Awaiting responses")
    end

    click_link "Send emails to consultees"
    expect(page).to have_selector("h1", text: "Send emails to consultees")
    expect(page).to have_selector("h2", text: "Step 1 Select the consultees to consult")
    expect(page).to have_selector("h2", text: "Step 2 Select consultation type")

    within "#consultees" do
      within "tbody tr.external-consultee" do
        expect(page).to have_unchecked_field("Select consultee")
        expect(page).to have_selector("td.consultee-name", text: "Consultations")
        expect(page).to have_selector("td.consultee-name", text: "Planning Department, GLA")
        expect(page).to have_selector("td.consultee-last-contacted", text: start_date)
        expect(page).to have_selector("td.consultee-status", text: "Awaiting response")
      end
      within "tbody tr.internal-consultee" do
        expect(page).to have_unchecked_field("Select consultee")
        expect(page).to have_selector("td.consultee-name", text: "Chris Wood")
        expect(page).to have_selector("td.consultee-name", text: "Tree Officer, PlanX Council")
        expect(page).to have_selector("td.consultee-last-contacted", text: start_date)
        expect(page).to have_selector("td.consultee-status", text: "Awaiting response")
      end
    end

    accept_confirm(text: "Send emails to consultees?") do
      click_button "Send emails to consultees"
    end

    expect(page).to have_selector("[role=alert] li", text: "Please select at least one consultee")

    within "#consultees" do
      within "table tbody tr:first-child" do
        check "Select consultee"
      end
    end

    select "Resending to existing consultees"

    find("summary", text: "View/edit email template").click
    fill_in "Message body", with: "Please respond to the message below by {{close_date}}\n\n" + find("textarea").text

    accept_confirm(text: "Send emails to consultees?") do
      click_button "Send emails to consultees"
    end

    expect(page).to have_selector("[role=alert] li", text: "The message body contains an invalid placeholder '{{close_date}}'")

    fill_in "Message body", with: find("textarea").text.gsub("{{close_date}}", consultee_response_date)

    within "#response-period" do
      fill_in "consultation[consultee_response_period]", with: 5
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
        activity_type: "consultee_emails_resent"
      )).to exist

      within "#consultee-tasks" do
        expect(page).to have_selector("li:nth-child(2) a", text: "Send emails to consultees")
        expect(page).to have_selector("li:nth-child(2) .govuk-tag", text: "Awaiting responses")
      end
    end.to have_enqueued_job(SendConsulteeEmailJob).exactly(:once)

    external =
      stub_request(:post, "#{notify_url}/email")
        .with(body: hash_including(
          {
            email_address: "planning@london.gov.uk",
            email_reply_to_id: "4485df6f-a728-41ed-bc46-cdb2fc6789aa",
            personalisation: hash_including(
              "body" => a_string_starting_with("Please respond to the message below by #{consultee_response_date}")
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
    expect(UpdateConsulteeEmailStatusJob).to have_been_enqueued.exactly(:once)

    click_link "Send emails to consultees"
    expect(page).to have_selector("h1", text: "Send emails to consultees")

    within "#consultees" do
      within "tbody tr.external-consultee" do
        expect(page).to have_unchecked_field("Select consultee")
        expect(page).to have_selector("td.consultee-name", text: "Consultations")
        expect(page).to have_selector("td.consultee-name", text: "Planning Department, GLA")
        expect(page).to have_selector("td.consultee-last-contacted", text: start_date)
        expect(page).to have_selector("td.consultee-status", text: "Sending")
      end
    end

    external_status =
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

    expect(consultee.email_sent_at).to be_within(1.second).of(email_sent_at)
    expect(consultee.email_delivered_at).to be_within(1.second).of(email_delivered_at)
    expect(consultee.last_email_sent_at).to be_within(1.minute).of(now)
    expect(consultee.last_email_delivered_at).to be_within(1.minute).of(now)
    expect(consultee.expires_at.to_date).to eq(today + 5.days)

    expect(consultee.emails.last.body).to include("Please respond to the message below by #{consultee_response_date}")
    expect(consultee.emails.last.body).to include("Please submit your comments by #{consultee_response_date} by using the web form.")

    click_link "Back"
    expect(page).to have_selector("h1", text: "Consultation")

    within("#consultation-end-date") do
      expect(page).to have_text("Consultation end #{end_date.to_fs(:day_month_year_slashes)}")
    end

    within "#consultee-tasks" do
      expect(page).to have_selector("li:nth-child(2) .govuk-tag", text: "Awaiting responses")
    end

    click_link "Send emails to consultees"
    expect(page).to have_selector("h1", text: "Send emails to consultees")

    within "#consultees" do
      within "tbody tr.external-consultee" do
        expect(page).to have_unchecked_field("Select consultee")
        expect(page).to have_selector("td.consultee-name", text: "Consultations")
        expect(page).to have_selector("td.consultee-name", text: "Planning Department, GLA")
        expect(page).to have_selector("td.consultee-last-contacted", text: start_date)
        expect(page).to have_selector("td.consultee-status", text: "Awaiting response")
      end

      within "tbody tr.internal-consultee" do
        expect(page).to have_unchecked_field("Select consultee")
        expect(page).to have_selector("td.consultee-name", text: "Chris Wood")
        expect(page).to have_selector("td.consultee-name", text: "Tree Officer, PlanX Council")
        expect(page).to have_selector("td.consultee-last-contacted", text: start_date)
        expect(page).to have_selector("td.consultee-status", text: "Awaiting response")
      end
    end
  end
end
