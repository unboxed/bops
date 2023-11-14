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

  let(:current_date) do
    Date.current.to_fs(:day_month_year_slashes)
  end

  let(:start_date) do
    1.business_day.from_now.beginning_of_day
  end

  let(:end_date) do
    start_date.end_of_day + 21.days
  end

  let(:now) do
    Time.current
  end

  let(:period) do
    (end_date - now).seconds.in_days.floor
  end

  before do
    create(
      :contact, :external,
      name: "Consultations",
      role: "Planning Department",
      organisation: "GLA",
      email_address: "planning@london.gov.uk"
    )

    create(
      :contact, :internal,
      local_authority:,
      name: "Chris Wood",
      role: "Tree Officer",
      organisation: local_authority.council_name,
      email_address: "chris.wood@#{local_authority.subdomain}.gov.uk"
    )
  end

  it "sends emails to consultees" do
    sign_in assessor

    visit "/planning_applications/#{planning_application.id}"
    expect(page).to have_selector("h1", text: "Application")

    within "#consultation-section" do
      expect(page).to have_selector("li:first-child a", text: "Consultees, neighbours and publicity")
      expect(page).to have_selector("li:first-child .govuk-tag", text: "Not started")
    end

    click_link "Consultees, neighbours and publicity"
    expect(page).to have_selector("h1", text: "Consultation")

    within "#dates-and-assignment-details" do
      expect(page).to have_text("Consultation start date: Not yet started")
      expect(page).to have_text("Consultation end date: Not yet started")
    end

    within "#consultee-tasks" do
      expect(page).to have_selector("li:first-child a", text: "Send emails to consultees")
      expect(page).to have_selector("li:first-child .govuk-tag", text: "Not started")
    end

    click_link "Send emails to consultees"
    expect(page).to have_selector("h1", text: "Send emails to consultees")
    expect(page).to have_selector("h2", text: "1) Select the consultees to consult")
    expect(page).to have_selector("h2", text: "2) Send email to selected consultees")
    expect(page).not_to have_selector("h2", text: "3) Is this a reconsultation?")

    accept_confirm(text: "Send emails to consultees?") do
      click_button "Send emails to consultees"
    end

    expect(page).to have_selector("[role=alert] li", text: "Please select at least one consultee")

    fill_in "Search for consultees", with: "GLA"
    expect(page).to have_selector("#add-consultee__listbox li:first-child", text: "Consultations (Planning Department, GLA)")

    pick "Consultations (Planning Department, GLA)", from: "#add-consultee"
    expect(page).to have_field("Search for consultees", with: "Consultations")

    click_button "Add consultee"

    within "#external-consultees" do
      within "table tbody tr:first-child" do
        expect(page).to have_checked_field("Select consultee")
        expect(page).to have_selector("td:nth-child(2)", text: "Consultations")
        expect(page).to have_selector("td:nth-child(2)", text: "Planning Department, GLA")
        expect(page).to have_selector("td:nth-child(3)", text: "–")
        expect(page).to have_selector("td:nth-child(4)", text: "–")
        expect(page).to have_selector("td:nth-child(5)", text: "Not consulted")
      end
    end

    fill_in "Search for consultees", with: "Tree Officer"
    expect(page).to have_selector("#add-consultee__listbox li:first-child", text: "Chris Wood (Tree Officer, PlanX Council)")

    pick "Chris Wood (Tree Officer, PlanX Council)", from: "#add-consultee"
    expect(page).to have_field("Search for consultees", with: "Chris Wood")

    click_button "Add consultee"

    within "#internal-consultees" do
      within "table tbody tr:first-child" do
        expect(page).to have_checked_field("Select consultee")
        expect(page).to have_selector("td:nth-child(2)", text: "Chris Wood")
        expect(page).to have_selector("td:nth-child(2)", text: "Tree Officer, PlanX Council")
        expect(page).to have_selector("td:nth-child(3)", text: "–")
        expect(page).to have_selector("td:nth-child(4)", text: "–")
        expect(page).to have_selector("td:nth-child(5)", text: "Not consulted")
      end
    end

    toggle "View/edit email template"

    fill_in "Message subject", with: "Consultation for planning application %<reference>s"

    expect do
      accept_confirm(text: "Send emails to consultees?") do
        click_button "Send emails to consultees"
      end

      expect(page).to have_selector("h1", text: "Consultation")
      expect(page).to have_selector("[role=alert] h3", text: "Emails have been sent to the selected consultees.")

      expect(Audit.where(
        planning_application_id: planning_application.id,
        user_id: assessor.id,
        activity_type: "consultee_emails_sent"
      )).to exist

      within "#consultee-tasks" do
        expect(page).to have_selector("li:first-child a", text: "Send emails to consultees")
        expect(page).to have_selector("li:first-child .govuk-tag", text: "In progress")
      end
    end.to have_enqueued_job(SendConsulteeEmailJob).exactly(:twice)

    internal = \
      stub_request(:post, "#{notify_url}/email")
        .with(body: hash_including(
          {
            email_address: "chris.wood@planx.gov.uk",
            email_reply_to_id: "4485df6f-a728-41ed-bc46-cdb2fc6789aa",
            personalisation: hash_including(
              "subject" => "Consultation for planning application #{planning_application.reference}"
            )
          }
        ))
        .to_return(
          status: 200,
          headers: {
            "Content-Type" => "application/json"
          },
          body: {
            id: "ee35ce55-f32e-4269-a217-18517745fe8b"
          }.to_json
        )

    external = \
      stub_request(:post, "#{notify_url}/email")
        .with(body: hash_including(
          {
            email_address: "planning@london.gov.uk",
            email_reply_to_id: "4485df6f-a728-41ed-bc46-cdb2fc6789aa",
            personalisation: hash_including(
              "subject" => "Consultation for planning application #{planning_application.reference}"
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
    expect(internal).to have_been_requested
    expect(external).to have_been_requested
    expect(UpdateConsulteeEmailStatusJob).to have_been_enqueued.exactly(:twice)

    click_link "Send emails to consultees"
    expect(page).to have_selector("h1", text: "Send emails to consultees")

    within "#external-consultees" do
      within "table tbody tr:first-child" do
        expect(page).to have_unchecked_field("Select consultee")
        expect(page).to have_selector("td:nth-child(2)", text: "Consultations")
        expect(page).to have_selector("td:nth-child(2)", text: "Planning Department, GLA")
        expect(page).to have_selector("td:nth-child(3)", text: "–")
        expect(page).to have_selector("td:nth-child(4)", text: "–")
        expect(page).to have_selector("td:nth-child(5)", text: "Sending")
      end
    end

    within "#internal-consultees" do
      within "table tbody tr:first-child" do
        expect(page).to have_unchecked_field("Select consultee")
        expect(page).to have_selector("td:nth-child(2)", text: "Chris Wood")
        expect(page).to have_selector("td:nth-child(2)", text: "Tree Officer, PlanX Council")
        expect(page).to have_selector("td:nth-child(3)", text: "–")
        expect(page).to have_selector("td:nth-child(4)", text: "–")
        expect(page).to have_selector("td:nth-child(5)", text: "Sending")
      end
    end

    internal_status = \
      stub_request(:get, "#{notify_url}/ee35ce55-f32e-4269-a217-18517745fe8b")
        .to_return(
          status: 200,
          headers: {
            "Content-Type" => "application/json"
          },
          body: {
            status: "delivered"
          }.to_json
        )

    external_status = \
      stub_request(:get, "#{notify_url}/48025d96-abc9-4b1d-a519-3cbc1c7f700b")
        .to_return(
          status: 200,
          headers: {
            "Content-Type" => "application/json"
          },
          body: {
            status: "permanent-failure"
          }.to_json
        )

    perform_enqueued_jobs
    expect(internal_status).to have_been_requested
    expect(external_status).to have_been_requested

    click_link "Back"
    expect(page).to have_selector("h1", text: "Consultation")

    within "#consultee-tasks" do
      expect(page).to have_selector("li:first-child .govuk-tag", text: "Failed")
    end

    click_link "Send emails to consultees"
    expect(page).to have_selector("h1", text: "Send emails to consultees")

    within "#external-consultees" do
      within "table tbody tr:first-child" do
        expect(page).to have_unchecked_field("Select consultee")
        expect(page).to have_selector("td:nth-child(2)", text: "Consultations")
        expect(page).to have_selector("td:nth-child(2)", text: "Planning Department, GLA")
        expect(page).to have_selector("td:nth-child(3)", text: "–")
        expect(page).to have_selector("td:nth-child(4)", text: "–")
        expect(page).to have_selector("td:nth-child(5)", text: "Failed")
      end
    end

    within "#internal-consultees" do
      within "table tbody tr:first-child" do
        expect(page).to have_unchecked_field("Select consultee")
        expect(page).to have_selector("td:nth-child(2)", text: "Chris Wood")
        expect(page).to have_selector("td:nth-child(2)", text: "Tree Officer, PlanX Council")
        expect(page).to have_selector("td:nth-child(3)", text: "#{period} days")
        expect(page).to have_selector("td:nth-child(4)", text: current_date)
        expect(page).to have_selector("td:nth-child(5)", text: "Awaiting response")
      end
    end

    within "#external-consultees" do
      within "table tbody tr:first-child" do
        check "Select consultee"
      end
    end

    toggle "View/edit email template"

    fill_in "Message subject", with: "Resend: Consultation for planning application %<reference>s"

    expect do
      accept_confirm(text: "Send emails to consultees?") do
        click_button "Send emails to consultees"
      end

      expect(page).to have_selector("h1", text: "Consultation")
      expect(page).to have_selector("[role=alert] h3", text: "Emails have been sent to the selected consultees.")

      within "#consultee-tasks" do
        expect(page).to have_selector("li:first-child a", text: "Send emails to consultees")
        expect(page).to have_selector("li:first-child .govuk-tag", text: "Awaiting responses")
      end
    end.to have_enqueued_job(SendConsulteeEmailJob).exactly(:once)

    resend = \
      stub_request(:post, "#{notify_url}/email")
        .with(body: hash_including(
          {
            email_address: "planning@london.gov.uk",
            email_reply_to_id: "4485df6f-a728-41ed-bc46-cdb2fc6789aa",
            personalisation: hash_including(
              "subject" => "Resend: Consultation for planning application #{planning_application.reference}"
            )
          }
        ))
        .to_return(
          status: 200,
          headers: {
            "Content-Type" => "application/json"
          },
          body: {
            id: "17d69fb7-5d4c-400b-af11-2952266d2e2b"
          }.to_json
        )

    perform_enqueued_jobs(at: Time.current)
    expect(resend).to have_been_requested
    expect(UpdateConsulteeEmailStatusJob).to have_been_enqueued.exactly(:once)

    click_link "Send emails to consultees"
    expect(page).to have_selector("h1", text: "Send emails to consultees")

    within "#external-consultees" do
      within "table tbody tr:first-child" do
        expect(page).to have_unchecked_field("Select consultee")
        expect(page).to have_selector("td:nth-child(2)", text: "Consultations")
        expect(page).to have_selector("td:nth-child(2)", text: "Planning Department, GLA")
        expect(page).to have_selector("td:nth-child(3)", text: "–")
        expect(page).to have_selector("td:nth-child(4)", text: "–")
        expect(page).to have_selector("td:nth-child(5)", text: "Sending")
      end
    end

    resend_status = \
      stub_request(:get, "#{notify_url}/17d69fb7-5d4c-400b-af11-2952266d2e2b")
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
    expect(resend_status).to have_been_requested

    click_link "Back"
    expect(page).to have_selector("h1", text: "Consultation")

    within "#dates-and-assignment-details" do
      expect(page).to have_text("Consultation start date: #{start_date.to_date.to_fs}")
      expect(page).to have_text("Consultation end date: #{end_date.to_date.to_fs}")
      expect(page).to have_text("#{period} days remaining")
    end

    within "#consultee-tasks" do
      expect(page).to have_selector("li:first-child .govuk-tag", text: "Awaiting responses")
    end

    click_link "Send emails to consultees"
    expect(page).to have_selector("h1", text: "Send emails to consultees")

    within "#external-consultees" do
      within "table tbody tr:first-child" do
        expect(page).to have_unchecked_field("Select consultee")
        expect(page).to have_selector("td:nth-child(2)", text: "Consultations")
        expect(page).to have_selector("td:nth-child(2)", text: "Planning Department, GLA")
        expect(page).to have_selector("td:nth-child(3)", text: "#{period} days")
        expect(page).to have_selector("td:nth-child(4)", text: current_date)
        expect(page).to have_selector("td:nth-child(5)", text: "Awaiting response")
      end
    end
  end
end
