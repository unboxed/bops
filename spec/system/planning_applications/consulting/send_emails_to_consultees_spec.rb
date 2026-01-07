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

  let(:planning_application2) do
    create(
      :planning_application,
      :pre_application,
      :in_assessment,
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

  let(:current_date) do
    now.to_fs(:day_month_year_slashes)
  end

  let(:start_date) do
    1.business_day.since(now)
  end

  let(:end_date) do
    start_date + 21.days
  end

  let(:now) do
    Time.zone.today
  end

  let(:period) do
    (end_date - now).floor
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

    visit "/planning_applications/#{planning_application.reference}"
    expect(page).to have_selector("h1", text: "Application")

    within "#consultation-section" do
      expect(page).to have_selector("li:first-child a", text: "Consultees, neighbours and publicity")
      expect(page).to have_selector("li:first-child .govuk-tag", text: "Not started")
    end

    click_link "Consultees, neighbours and publicity"
    expect(page).to have_selector("h1", text: "Consultation")

    within "#consultation-end-date" do
      expect(page).to have_text("Consultation end Not yet started")
    end

    within "#consultee-tasks" do
      expect(page).to have_selector("li:nth-child(2) a", text: "Send emails to consultees")
      expect(page).to have_selector("li:nth-child(2) .govuk-tag", text: "Not started")
    end

    click_link "Send emails to consultees"
    expect(page).to have_selector("h1", text: "Send emails to consultees")
    expect(page).to have_selector("h2", text: "Step 1 Select the consultees to consult")
    expect(page).to have_selector("h2", text: "Step 2 Select consultation type")
    expect(page).to have_selector("h2", text: "Step 3 Set response period")
    expect(page).not_to have_selector("h2", text: "Step 3 Is this a reconsultation?")

    accept_confirm(text: "Send emails to consultees?") do
      click_button "Send emails to consultees"
    end

    expect(page).to have_selector("[role=alert] li", text: "Please select at least one consultee")

    visit "/planning_applications/#{planning_application.reference}/consultees"

    fill_in "Search for consultees", with: "GLA"
    expect(page).to have_selector("#add-consultee__listbox li:first-child", text: "Consultations (Planning Department, GLA)")

    pick "Consultations (Planning Department, GLA)", from: "#add-consultee"
    expect(page).to have_field("Search for consultees", with: "Consultations")

    click_button "Add consultee"

    fill_in "Search for consultees", with: "Tree Officer"
    expect(page).to have_selector("#add-consultee__listbox li:first-child", text: "Chris Wood (Tree Officer, PlanX Council)")

    pick "Chris Wood (Tree Officer, PlanX Council)", from: "#add-consultee"
    expect(page).to have_field("Search for consultees", with: "Chris Wood")

    click_button "Add consultee"

    visit "/planning_applications/#{planning_application.reference}/consultee/emails"

    within "#consultees" do
      within "tbody tr.external-consultee" do
        expect(page).to have_selector("td.consultee-name", text: "Consultations")
        expect(page).to have_selector("td.consultee-name", text: "Planning Department, GLA")
        expect(page).to have_selector("td.consultee-constraint", text: "–")
        expect(page).to have_selector("td.consultee-origin", text: "external")
        expect(page).to have_selector("td.consultee-last-contacted", text: "–")
        expect(page).to have_selector("td.consultee-status", text: "Not consulted")
        check "Select consultee"
      end

      within "tbody tr.internal-consultee" do
        expect(page).to have_selector("td.consultee-name", text: "Chris Wood")
        expect(page).to have_selector("td.consultee-name", text: "Tree Officer, PlanX Council")
        expect(page).to have_selector("td.consultee-constraint", text: "–")
        expect(page).to have_selector("td.consultee-origin", text: "internal")
        expect(page).to have_selector("td.consultee-last-contacted", text: "–")
        expect(page).to have_selector("td.consultee-status", text: "Not consulted")
        check "Select consultee"
      end
    end

    toggle "View/edit email template"

    fill_in "Message subject", with: "Consultation for planning application {{uuid}}"

    accept_confirm(text: "Send emails to consultees?") do
      click_button "Send emails to consultees"
    end

    expect(page).to have_selector("[role=alert] li", text: "The message subject contains an invalid placeholder '{{uuid}}'")

    fill_in "Message subject", with: ""
    fill_in "Message body", with: ""

    accept_confirm(text: "Send emails to consultees?") do
      click_button "Send emails to consultees"
    end

    expect(page).to have_selector("[role=alert] li", text: "Please enter a message subject")
    expect(page).to have_selector("[role=alert] li", text: "Please enter a message body")

    click_button "Reset message to default content"

    within "#response-period" do
      fill_in "consultation[consultee_response_period]", with: 10
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
        activity_type: "consultee_emails_sent"
      )).to exist

      within "#consultee-tasks" do
        expect(page).to have_selector("li:nth-child(2) a", text: "Send emails to consultees")
        expect(page).to have_selector("li:nth-child(2) .govuk-tag", text: "In progress")
      end
    end.to have_enqueued_job(SendConsulteeEmailJob).exactly(:twice)

    internal =
      stub_request(:post, "#{notify_url}/email")
        .with(body: hash_including(
          {
            email_address: "chris.wood@planx.gov.uk",
            email_reply_to_id: "4485df6f-a728-41ed-bc46-cdb2fc6789aa",
            personalisation: hash_including(
              "subject" => "Comments requested for #{planning_application.reference}"
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

    external =
      stub_request(:post, "#{notify_url}/email")
        .with(body: hash_including(
          {
            email_address: "planning@london.gov.uk",
            email_reply_to_id: "4485df6f-a728-41ed-bc46-cdb2fc6789aa",
            personalisation: hash_including(
              "subject" => "Comments requested for #{planning_application.reference}"
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

    within "#consultees" do
      within "tbody tr.external-consultee" do
        expect(page).to have_unchecked_field("Select consultee")
        expect(page).to have_selector("td.consultee-name", text: "Consultations")
        expect(page).to have_selector("td.consultee-name", text: "Planning Department, GLA")
        expect(page).to have_selector("td.consultee-constraint", text: "–")
        expect(page).to have_selector("td.consultee-origin", text: "external")
        expect(page).to have_selector("td.consultee-last-contacted", text: "–")
        expect(page).to have_selector("td.consultee-status", text: "Sending")
      end
    end

    within "#consultees" do
      within "tbody tr.internal-consultee" do
        expect(page).to have_unchecked_field("Select consultee")
        expect(page).to have_selector("td.consultee-name", text: "Chris Wood")
        expect(page).to have_selector("td.consultee-name", text: "Tree Officer, PlanX Council")
        expect(page).to have_selector("td.consultee-constraint", text: "–")
        expect(page).to have_selector("td.consultee-origin", text: "internal")
        expect(page).to have_selector("td.consultee-last-contacted", text: "–")
        expect(page).to have_selector("td.consultee-status", text: "Sending")
      end
    end

    internal_status =
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

    external_status =
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
      expect(page).to have_selector("li:nth-child(2) .govuk-tag", text: "Failed")
    end

    click_link "Send emails to consultees"
    expect(page).to have_selector("h1", text: "Send emails to consultees")

    within "#consultees" do
      within "table tbody tr:first-child" do
        expect(page).to have_unchecked_field("Select consultee")
        expect(page).to have_selector("td.consultee-name", text: "Consultations")
        expect(page).to have_selector("td.consultee-name", text: "Planning Department, GLA")
        expect(page).to have_selector("td.consultee-last-contacted", text: "–")
        expect(page).to have_selector("td.consultee-status", text: "Failed")
      end

      within "table tbody tr:nth-child(2)" do
        expect(page).to have_unchecked_field("Select consultee")
        expect(page).to have_selector("td.consultee-name", text: "Chris Wood")
        expect(page).to have_selector("td.consultee-name", text: "Tree Officer, PlanX Council")
        expect(page).to have_selector("td.consultee-last-contacted", text: current_date)
        expect(page).to have_selector("td.consultee-status", text: "Awaiting response")
      end
    end

    within "#consultees" do
      within "table tbody tr:first-child" do
        check "Select consultee"
      end
    end

    toggle "View/edit email template"

    fill_in "Message subject", with: "Resend: Consultation for planning application {{reference}}"

    within "#response-period" do
      fill_in "consultation[consultee_response_period]", with: 15
    end

    expect do
      accept_confirm(text: "Send emails to consultees?") do
        click_button "Send emails to consultees"
      end

      expect(page).to have_selector("h1", text: "Consultation")
      expect(page).to have_selector("[role=alert] h3", text: "Emails have been sent to the selected consultees.")

      within "#consultee-tasks" do
        expect(page).to have_selector("li:nth-child(2) a", text: "Send emails to consultees")
        expect(page).to have_selector("li:nth-child(2) .govuk-tag", text: "Awaiting responses")
      end
    end.to have_enqueued_job(SendConsulteeEmailJob).exactly(:once)

    resend =
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

    within "#consultees" do
      within "table tbody tr.external-consultee" do
        expect(page).to have_unchecked_field("Select consultee")
        expect(page).to have_selector("td.consultee-name", text: "Consultations")
        expect(page).to have_selector("td.consultee-name", text: "Planning Department, GLA")
        expect(page).to have_selector("td.consultee-last-contacted", text: "–")
        expect(page).to have_selector("td.consultee-status", text: "Sending")
      end
    end

    resend_status =
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

    within "#consultation-end-date" do
      expect(page).to have_text("Consultation end #{end_date.to_date.to_fs(:day_month_year_slashes)}")
    end

    within "#consultee-tasks" do
      expect(page).to have_selector("li:first-child .govuk-tag", text: "Awaiting responses")
    end

    click_link "Send emails to consultees"
    expect(page).to have_selector("h1", text: "Send emails to consultees")

    within "#consultees" do
      within "tbody tr.external-consultee" do
        expect(page).to have_unchecked_field("Select consultee")
        expect(page).to have_selector("td.consultee-name", text: "Consultations")
        expect(page).to have_selector("td.consultee-name", text: "Planning Department, GLA")
        expect(page).to have_selector("td.consultee-last-contacted", text: current_date)
        expect(page).to have_selector("td.consultee-status", text: "Awaiting response")
      end
    end
  end

  context "when the application has not been started" do
    let(:planning_application) do
      create(
        :planning_application,
        :not_started,
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

    it "doesn't allow access to the consultation" do
      sign_in assessor

      visit "/planning_applications/#{planning_application.reference}"
      expect(page).to have_selector("h1", text: "Application")

      within "#consultation-section" do
        expect(page).to have_selector("li:first-child", text: "Consultees, neighbours and publicity")
        expect(page).to have_selector("li:first-child", text: "Cannot start yet")
      end
    end
  end

  context "when the application has been invalidated" do
    let(:planning_application) do
      create(
        :planning_application,
        :invalidated,
        :from_planx_prior_approval,
        :with_boundary_geojson,
        application_type:,
        local_authority:,
        api_user:,
        agent_email: "agent@example.com",
        applicant_email: "applicant@example.com"
      )
    end

    it "doesn't allow access to the consultation" do
      sign_in assessor

      visit "/planning_applications/#{planning_application.reference}"
      expect(page).to have_selector("h1", text: "Application")

      within "#consultation-section" do
        expect(page).to have_selector("li:first-child", text: "Consultees, neighbours and publicity")
        expect(page).to have_selector("li:first-child", text: "Cannot start yet")
      end
    end
  end

  context "when an application is a pre-app" do
    before do
      planning_application2.consultation
    end

    it "allows emails to be sent without making public" do
      sign_in assessor

      visit "/planning_applications/#{planning_application2.reference}"
      expect(page).to have_selector("h1", text: "Application")
      expect(page).not_to have_text("Public on BOPS Public Portal")

      within "#consultation-section" do
        expect(page).to have_selector("li:first-child a", text: "Consultees")
        expect(page).to have_selector("li:first-child .govuk-tag", text: "Not started")
      end

      click_link "Consultees"
      expect(page).to have_selector("h1", text: "Determine consultation requirement")

      within ".bops-sidebar" do
        expect(page).not_to have_text("Add and assign consultees")
      end

      choose "Yes"
      click_button "Save and mark as complete"

      expect(page).to have_content("Consultation requirement was successfully updated")

      within ".bops-sidebar" do
        expect(page).to have_link("Add and assign consultees")
        expect(page).to have_link("Send emails to consultees")
      end

      click_link "Add and assign consultees"
      expect(page).to have_selector("h1", text: "Add and assign consultees")

      fill_in "Search for consultees", with: "GLA"
      expect(page).to have_selector("#add-consultee__listbox li:first-child", text: "Consultations (Planning Department, GLA)")

      pick "Consultations (Planning Department, GLA)", from: "#add-consultee"
      expect(page).to have_field("Search for consultees", with: "Consultations")

      click_button "Add consultee"

      within ".consultee-table tbody" do
        expect(page).to have_content("Planning Department, GLA")
      end

      within ".bops-sidebar" do
        click_link "Send emails to consultees"
      end
      expect(page).to have_selector("h1", text: "Send emails to consultees")

      within "#consultees" do
        within "tbody tr.external-consultee" do
          expect(page).to have_selector("td.consultee-name", text: "Consultations")
          expect(page).to have_selector("td.consultee-name", text: "Planning Department, GLA")
          expect(page).to have_selector("td.consultee-constraint", text: "–")
          expect(page).to have_selector("td.consultee-origin", text: "external")
          expect(page).to have_selector("td.consultee-last-contacted", text: "–")
          expect(page).to have_selector("td.consultee-status", text: "Not consulted")
          check "Select consultee"
        end
      end

      click_button "Send emails to consultees"

      expect(page).to have_content("Emails have been sent to the selected consultees")
    end
  end
end
