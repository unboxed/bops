# frozen_string_literal: true

require "rails_helper"
require "faraday"

RSpec.describe "Send letters to neighbours", :js, type: :system do
  let(:api_user) { create(:api_user, :planx) }
  let(:default_local_authority) { create(:local_authority, :default) }
  let(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }
  let!(:application_type) { create(:application_type, :prior_approval, local_authority: default_local_authority) }

  let(:planning_application) do
    create(:planning_application,
      :from_planx_prior_approval,
      :with_boundary_geojson,
      :published,
      application_type:,
      local_authority: default_local_authority,
      api_user:,
      agent_email: "agent@example.com",
      applicant_email: "applicant@example.com")
  end

  let(:consultation) do
    planning_application.consultation
  end

  let!(:neighbour) { create(:neighbour, consultation:, address: "60-62, Commercial Street, E16LT") }
  let!(:reference) { planning_application.reference }
  let(:slug) { "consultees-neighbours-and-publicity/neighbours/send-letters-to-neighbours" }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("BOPS_ENVIRONMENT", "development").and_return("production")

    sign_in assessor
  end

  context "when sending letters" do
    before do
      travel_to(Time.zone.local(2023, 9, 1, 10))

      neighbour = create(:neighbour, consultation:, address: "123, Made Up Street, London, W5 67S")
      neighbour_letter = create(:neighbour_letter, neighbour:, status: "submitted", notify_id: "123")

      stub_send_letter(status: 200)
      stub_get_notify_status(notify_id: neighbour_letter.notify_id)

      visit "/planning_applications/#{reference}/#{slug}"
    end

    it "successfully sends letters to the neighbours and a copy of the letter to the applicant" do
      expect(PlanningApplicationMailer).to receive(:neighbour_consultation_letter_copy_mail).with(planning_application, "agent@example.com").and_call_original
      expect(PlanningApplicationMailer).to receive(:neighbour_consultation_letter_copy_mail).with(planning_application, "applicant@example.com").and_call_original

      expect(page).to have_content("60-62, Commercial Street")
      expect(page).to have_content("123, Made Up Street")

      within "#selected-neighbours-list" do
        uncheck "Select 123, Made Up Street"
      end

      click_button "Send letters"
      expect(page).to have_content("Letters have been sent to neighbours")

      expect(planning_application.consultation.reload.letter_copy_sent_at).to eq(Time.zone.local(2023, 9, 1, 10))

      expect(NeighbourLetter.last.text).to include("An application has been made for the development described below:")

      # View audit log
      visit "/planning_applications/#{reference}/audits"
      within("#audit_#{Audit.last.id}") do
        expect(page).to have_content("Neighbour letters sent")
        expect(page).to have_content(assessor.name)
        expect(page).to have_content(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
      end
      within("#audit_#{Audit.last(2).first.id}") do
        expect(page).to have_content("Neighbour consultation letter copy email sent")
        expect(page).to have_content(assessor.name)
        expect(page).to have_content("Neighbour letter copy sent by email to agent@example.com, applicant@example.com")
        expect(page).to have_content(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
      end
    end

    it "I can edit the letter being sent" do
      expect(PlanningApplicationMailer).to receive(:neighbour_consultation_letter_copy_mail).twice.with(planning_application, "agent@example.com").and_call_original
      expect(PlanningApplicationMailer).to receive(:neighbour_consultation_letter_copy_mail).with(planning_application, "applicant@example.com").and_call_original

      expect(page).to have_content("60-62, Commercial Street, E16LT")

      expect(page).to have_content("Choose which letter to send")

      page.find("summary", text: /View\/edit letter template/).click
      fill_in "Neighbour letter", with: "This is some content I'm putting in"

      # Toggle the govuk-details so that the submit button is on-screen
      page.find("summary", text: /View\/edit letter template/).click

      click_button "Send letters"
      expect(page).to have_content("Letters have been sent to neighbours")

      expect(planning_application.consultation.reload.letter_copy_sent_at).to eq(Time.zone.local(2023, 9, 1, 10))

      expect(NeighbourLetter.last.text).to eq("This is some content I'm putting in")

      expect(PlanningApplicationMailer.neighbour_consultation_letter_copy_mail(planning_application, planning_application.agent_email).body)
        .to include("This is some content I'm putting in")
    end

    it "allows overriding the response period" do
      expect(find("#tasks-send-letters-to-neighbours-form-deadline-extension-field").value).to eq("21")
      fill_in "tasks-send-letters-to-neighbours-form-deadline-extension-field", with: "48"

      click_button "Send letters"
      expect(page).to have_current_path("/planning_applications/#{reference}/#{slug}")
      expect(page).to have_content("Letters have been sent to neighbours")

      expect(planning_application.consultation.reload.end_date).to eq(48.days.from_now.to_date)
    end

    it "fails if no response period is set" do
      fill_in "tasks-send-letters-to-neighbours-form-deadline-extension-field", with: " "
      click_button "Send letters"
      expect(page).to have_content("Enter Deadline extension")
      expect(planning_application.consultation.reload.end_date).to be_nil
    end
  end

  it "shows the status of letters that have been sent" do
    neighbour = create(:neighbour, consultation:)
    neighbour_letter = create(:neighbour_letter, neighbour:, status: "submitted", notify_id: "123")

    stub_get_notify_status(notify_id: neighbour_letter.notify_id)
    NeighbourLetterStatusUpdateJob.perform_later(consultation)
    perform_enqueued_jobs

    visit "/planning_applications/#{reference}/#{slug}"

    expect(page).to have_content(neighbour.address)
    expect(page).to have_content("Posted")
  end

  context "when letters have already been sent" do
    let(:neighbour1) { create(:neighbour, address: "1, Test Lane, E1 5AT", consultation:) }
    let(:neighbour2) { create(:neighbour, address: "3, Test Lane, E1 5AT", consultation:) }

    before do
      travel_to(2.weeks.ago) do
        consultation.start_deadline
      end

      neighbour_letter1 = create(:neighbour_letter, neighbour: neighbour1, status: "submitted", notify_id: "123")
      neighbour_letter2 = create(:neighbour_letter, neighbour: neighbour2, status: "submitted", notify_id: "456")
      neighbour1.touch(:last_letter_sent_at)
      neighbour2.touch(:last_letter_sent_at)
      stub_get_notify_status(notify_id: neighbour_letter1.notify_id)
      stub_get_notify_status(notify_id: neighbour_letter2.notify_id)
    end

    it "shows that letters have been sent" do
      visit "/planning_applications/#{reference}/consultees-neighbours-and-publicity/neighbours/send-letters-to-neighbours"

      within("#selected-neighbours-list") do
        expect(page).to have_content(neighbour1.address)
        expect(page).to have_content(neighbour2.address)
      end
    end

    it "allows resending of letters" do
      visit "/planning_applications/#{reference}/#{slug}"

      select "Renotification"
      fill_in("Resend reason",
        with: "Previous letter mistakenly listed applicant's address as Buckingham Palace.")

      orig_deadline = consultation.end_date

      click_button "Send letters"
      expect(page).to have_current_path("/planning_applications/#{reference}/#{slug}")
      expect(page).to have_content("Letters have been sent to neighbours")

      expect(neighbour1.neighbour_letters.length).to eq(2)
      expect(neighbour2.neighbour_letters.length).to eq(2)
      expect(consultation.reload.end_date).to be_after(orig_deadline)
    end

    it "does not resend letters unless selected" do
      visit "/planning_applications/#{reference}/#{slug}"

      click_button "Send letters"
      expect(neighbour1.neighbour_letters.length).to eq(1)
      expect(neighbour2.neighbour_letters.length).to eq(1)
    end

    it "includes a reason in the letter when resending letters" do
      visit "/planning_applications/#{reference}/#{slug}"

      select "Renotification"
      fill_in("Resend reason",
        with: "Previous letter mistakenly listed applicant's address as Buckingham Palace.")

      expect_any_instance_of(Notifications::Client).to receive(:send_letter).twice.with(template_id: anything,
        personalisation: hash_including(message: match_regex(/\A# Application updated\nThis application has been updated. Reason: Previous letter mistakenly listed applicant's address as Buckingham Palace.\n\n# The Town and Country Planning \(General Permitted Development\) \(England\) Order 2015 Part 1, Class A/))).and_call_original

      click_button "Send letters"
      expect(page).to have_current_path("/planning_applications/#{reference}/#{slug}")
      expect(page).to have_content("Letters have been sent to neighbours")

      expect(neighbour1.last_letter.text).to match_regex(/\A# Application updated\nThis application has been updated. Reason: Previous letter mistakenly listed applicant's address as Buckingham Palace.\n\n# The Town and Country Planning \(General Permitted Development\) \(England\) Order 2015 Part 1, Class A/)
      expect(neighbour2.last_letter.text).to match_regex(/\A# Application updated\nThis application has been updated. Reason: Previous letter mistakenly listed applicant's address as Buckingham Palace.\n\n# The Town and Country Planning \(General Permitted Development\) \(England\) Order 2015 Part 1, Class A/)
    end

    context "when the neighbour sent a comment" do
      before do
        neighbour1.update!(source: "sent_comment")
      end

      it "allows setting a reason when resend letters" do
        visit "/planning_applications/#{reference}/#{slug}"

        select "Renotification"
        fill_in("Resend reason",
          with: "Previous letter mistakenly listed applicant's address as Buckingham Palace.")

        expect_any_instance_of(Notifications::Client).to receive(:send_letter).twice.with(template_id: anything,
          personalisation: hash_including(message: match_regex(/# Application updated\nThis application has been updated. Reason: Previous letter mistakenly listed applicant's address as Buckingham Palace.\n\n# The Town and Country Planning \(General Permitted Development\) \(England\) Order 2015 Part 1, Class A/))).and_call_original

        click_button "Send letters"
        expect(page).to have_current_path("/planning_applications/#{reference}/#{slug}")
        expect(page).to have_content("Letters have been sent to neighbours")
      end
    end
  end
end
