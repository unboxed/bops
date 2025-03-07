# frozen_string_literal: true

require "rails_helper"
require "faraday"

RSpec.describe "Send letters to neighbours", type: :system, js: true do
  let(:api_user) { create(:api_user, name: "PlanX") }
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

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("BOPS_ENVIRONMENT", "development").and_return("production")

    sign_in assessor
    visit "/planning_applications/#{planning_application.reference}"
  end

  context "when sending letters" do
    before do
      travel_to(Time.zone.local(2023, 9, 1, 10))
      sign_in assessor
      visit "/planning_applications/#{reference}"

      neighbour = create(:neighbour, consultation:, address: "123, Made Up Street, London, W5 67S")
      neighbour_letter = create(:neighbour_letter, neighbour:, status: "submitted", notify_id: "123")

      stub_send_letter(status: 200)
      stub_get_notify_status(notify_id: neighbour_letter.notify_id)
    end

    it "successfully sends letters to the neighbours and a copy of the letter to the applicant" do
      expect(PlanningApplicationMailer).to receive(:neighbour_consultation_letter_copy_mail).with(planning_application, "agent@example.com").and_call_original
      expect(PlanningApplicationMailer).to receive(:neighbour_consultation_letter_copy_mail).with(planning_application, "applicant@example.com").and_call_original

      click_link "Consultees, neighbours and publicity"
      click_link "Send letters to neighbours"

      expect(page).to have_content("60-62, Commercial Street")
      expect(page).to have_content("123, Made Up Street")

      within "#selected-neighbours-list" do
        uncheck "Select 123, Made Up Street"
      end

      click_button "Confirm and send letters"
      expect(page).to have_content("Letters have been sent to neighbours and a copy of the letter has been sent to the applicant.")

      expect(planning_application.consultation.reload.letter_copy_sent_at).to eq(Time.zone.local(2023, 9, 1, 10))

      expect(NeighbourLetter.last.text).to include("A prior approval application has been made for the development described below:")

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

      sign_in assessor
      visit "/planning_applications/#{reference}"

      click_link "Consultees, neighbours and publicity"
      click_link "Send letters to neighbours"

      expect(page).to have_content("60-62, Commercial Street, E16LT")

      expect(page).to have_content("Choose which letter to send")

      # Rspec doesn't like govuk-details, doesn't think it's a link. This is the "View/edit template" link
      page.find(:xpath, "//*[@id='main-content']/div[2]/div/form/details/summary/span").click
      fill_in "Neighbour letter", with: "This is some content I'm putting in"

      # Toggle the govuk-details so that the submit button is on-screen
      page.find(:xpath, "//*[@id='main-content']/div[2]/div/form/details/summary/span").click

      click_button "Confirm and send letters"
      expect(page).to have_content("Letters have been sent to neighbours and a copy of the letter has been sent to the applicant.")

      expect(planning_application.consultation.reload.letter_copy_sent_at).to eq(Time.zone.local(2023, 9, 1, 10))

      expect(NeighbourLetter.last.text).to eq("This is some content I'm putting in")

      expect(PlanningApplicationMailer.neighbour_consultation_letter_copy_mail(planning_application, planning_application.agent_email).body)
        .to include("This is some content I'm putting in")
    end

    it "allows overriding the response period" do
      sign_in assessor
      visit "/planning_applications/#{reference}"

      click_link "Consultees, neighbours and publicity"
      click_link "Send letters to neighbours"

      expect(find("#consultation-deadline-extension-field").value).to eq("21")
      fill_in "consultation-deadline-extension-field", with: "48"

      click_button "Confirm and send letters"
      expect(page).to have_current_path("/planning_applications/#{reference}/consultation/neighbour_letters")
      expect(page).to have_content("Letters have been sent to neighbours")

      expect(planning_application.consultation.reload.end_date).to eq(48.days.from_now.to_date)
    end

    it "fails if no response period is set" do
      sign_in assessor
      visit "/planning_applications/#{reference}"

      click_link "Consultees, neighbours and publicity"
      click_link "Send letters to neighbours"

      fill_in "consultation-deadline-extension-field", with: " "
      click_button "Confirm and send letters"
      expect(page).to have_content("Deadline extension can't be blank")
      expect(planning_application.consultation.reload.end_date).to be nil
    end

    context "when planning application has not been made public on the BOPS Public Portal" do
      let(:planning_application) do
        create(:planning_application,
          :from_planx_prior_approval,
          application_type:,
          local_authority: default_local_authority)
      end

      it "prevents me sending letters and displays an alert" do
        expect(LetterSendingService).not_to receive(:new)

        sign_in assessor
        visit "/planning_applications/#{reference}"
        click_link "Consultees, neighbours and publicity"
        click_link "Send letters to neighbours"

        click_button "Confirm and send letters"

        within(".govuk-notification-banner--alert") do
          expect(page).to have_content("The planning application must be made public on the BOPS Public Portal before you can send letters to neighbours.")
          expect(page).to have_link("made public on the BOPS Public Portal", href: "/planning_applications/#{reference}/make_public")
        end
      end
    end
  end

  context "when there is a validation error on a provided address" do
    let(:neighbour) { Neighbour.new(address: "Cheese cottage", consultation:) }

    before do
      sign_in assessor
      visit "/planning_applications/#{reference}"
      click_link "Consultees, neighbours and publicity"
      click_link "Send letters to neighbours"
    end

    it "I can not send letters without neighbours" do
      click_button "Confirm and send letters"

      within(".govuk-notification-banner--alert") do
        expect(page).to have_content("There is a problem")
        expect(page).to have_content("Add some neighbours before sending letters")
      end
    end

    it "I can not send letters with an invalid address" do
      neighbour.save(validate: false)

      visit "/planning_applications/#{reference}"
      click_link "Consultees, neighbours and publicity"
      click_link "Send letters to neighbours"

      click_button "Confirm and send letters"

      within(".govuk-notification-banner--alert") do
        expect(page).to have_content("There is a problem")
        expect(page).to have_content("'Cheese cottage' is invalid")
        expect(page).to have_content("Enter the property name or number, followed by a comma")
        expect(page).to have_content("Enter the street name, followed by a comma")
        expect(page).to have_content("Enter a postcode, like AA11AA")
      end

      expect(NeighbourLetter.count).to eq(0)
      expect(ActionMailer::Base.deliveries.count).to eq(0)
      expect(consultation.status).to eq("not_started")
      expect(Audit.where(
        activity_type: "neighbour_letters_sent"
      )).not_to exist
    end
  end

  it "shows the status of letters that have been sent" do
    neighbour = create(:neighbour, consultation:)
    neighbour_letter = create(:neighbour_letter, neighbour:, status: "submitted", notify_id: "123")

    visit current_path
    stub_get_notify_status(notify_id: neighbour_letter.notify_id)

    click_link "Consultees, neighbours and publicity"
    click_link "Send letters to neighbours"

    # TODO the page does not get automatically updated with the result of the job, so here it needs to be refreshed
    perform_enqueued_jobs
    visit current_path

    expect(page).to have_content(neighbour.address)
    expect(page).to have_content("Posted")
  end

  describe "showing the status on the dashboard" do
    before do
      sign_in assessor
    end

    context "when there are no letters" do
      it "shows 'not started'" do
        visit "/planning_applications/#{reference}"
        click_link "Consultees, neighbours and publicity"
        expect(page).to have_content "Send letters to neighbours Not started"
      end
    end

    context "when there are only successful letters" do
      before do
        neighbour = create(:neighbour, consultation:)
        create(:neighbour_letter, neighbour:, status: "submitted", notify_id: "123")
      end

      it "shows 'completed'" do
        visit "/planning_applications/#{reference}"
        click_link "Consultees, neighbours and publicity"
        expect(page).to have_content "Send letters to neighbours Completed"
      end
    end

    context "when there are failed letters" do
      before do
        neighbour1 = create(:neighbour, address: "1, Test Lane, AAA111", consultation:)
        neighbour2 = create(:neighbour, address: "2, Test Lane, AAA111", consultation:)
        create(:neighbour_letter, neighbour: neighbour1, status: "submitted", notify_id: "123")
        create(:neighbour_letter, neighbour: neighbour2, status: "rejected", notify_id: "123")
      end

      it "shows 'failed'" do
        visit "/planning_applications/#{reference}"
        click_link "Consultees, neighbours and publicity"
        expect(page).to have_content "Send letters to neighbours Failed"
      end
    end
  end

  context "when letters have already been sent" do
    let(:neighbour) { create(:neighbour, address: "1, Test Lane, E1 5AT", consultation:) }

    before do
      travel_to(2.weeks.ago) do
        consultation.start_deadline
      end

      sign_in assessor

      neighbour_letter = create(:neighbour_letter, neighbour:, status: "submitted", notify_id: "123")
      neighbour.touch(:last_letter_sent_at)
      stub_get_notify_status(notify_id: neighbour_letter.notify_id)
    end

    it "shows that letters have been sent" do
      visit "/planning_applications/#{reference}"
      click_link "Consultees, neighbours and publicity"

      expect(page).not_to have_content "Send letters to neighbours Not started"
      expect(page).to have_content "Send letters to neighbours Completed"

      click_link "Send letters to neighbours"
      within("#selected-neighbours-list") do
        expect(page).to have_content(neighbour.address)
      end
    end

    it "allows resending of letters" do
      visit "/planning_applications/#{reference}"
      click_link "Consultees, neighbours and publicity"
      click_link "Send letters to neighbours"

      select "Renotification"
      fill_in("Resend reason",
        with: "Previous letter mistakenly listed applicant's address as Buckingham Palace.")

      orig_deadline = consultation.end_date

      click_button "Confirm and send letters"
      expect(page).to have_current_path("/planning_applications/#{reference}/consultation/neighbour_letters")
      expect(page).to have_content("Letters have been sent to neighbours")

      expect(neighbour.neighbour_letters.length).to eq(2)
      expect(consultation.reload.end_date).to be_after(orig_deadline)
    end

    it "does not resend letters unless selected" do
      visit "/planning_applications/#{reference}"
      click_link "Consultees, neighbours and publicity"
      click_link "Send letters to neighbours"

      click_button "Confirm and send letters"
      expect(neighbour.neighbour_letters.length).to eq(1)
    end

    it "requires a reason to resend letters" do
      visit "/planning_applications/#{reference}"
      click_link "Consultees, neighbours and publicity"
      click_link "Send letters to neighbours"

      select "Renotification"

      click_button "Confirm and send letters"
      expect(page).to have_content "Provide a reason when resending letters to previously contacted neighbours"
      expect(neighbour.neighbour_letters.length).to eq(1)
    end

    it "includes a reason in the letter when resending letters" do
      visit "/planning_applications/#{reference}"
      click_link "Consultees, neighbours and publicity"
      click_link "Send letters to neighbours"

      select "Renotification"
      fill_in("Resend reason",
        with: "Previous letter mistakenly listed applicant's address as Buckingham Palace.")

      expect_any_instance_of(Notifications::Client).to receive(:send_letter).with(template_id: anything,
        personalisation: hash_including(message: match_regex(/# Application updated\nThis application has been updated. Reason: Previous letter mistakenly listed applicant's address as Buckingham Palace.\n\n# Submit your comments by #{(1.business_day.from_now + 21.days).to_date.to_fs}\n\n# The Town and Country Planning \(General Permitted Development\) \(England\) Order 2015 Part 1, Class A\r?\n\r?\nDear Resident/))).and_call_original

      click_button "Confirm and send letters"
      expect(page).to have_current_path("/planning_applications/#{reference}/consultation/neighbour_letters")
      expect(page).to have_content("Letters have been sent to neighbours")
    end

    context "when the neighbour sent a comment" do
      before do
        neighbour.update!(source: "sent_comment")
      end

      it "allows setting a reason when resend letters" do
        visit "/planning_applications/#{reference}"
        click_link "Consultees, neighbours and publicity"
        click_link "Send letters to neighbours"

        select "Renotification"
        fill_in("Resend reason",
          with: "Previous letter mistakenly listed applicant's address as Buckingham Palace.")

        expect_any_instance_of(Notifications::Client).to receive(:send_letter).with(template_id: anything,
          personalisation: hash_including(message: match_regex(/# Application updated\nThis application has been updated. Reason: Previous letter mistakenly listed applicant's address as Buckingham Palace.\n\n# Submit your comments by #{(1.business_day.from_now + 21.days).to_date.to_fs}\n\n# The Town and Country Planning \(General Permitted Development\) \(England\) Order 2015 Part 1, Class A\r\n\r\nDear Resident/))).and_call_original

        click_button "Confirm and send letters"
        expect(page).to have_current_path("/planning_applications/#{reference}/consultation/neighbour_letters")
        expect(page).to have_content("Letters have been sent to neighbours")
      end
    end
  end
end
