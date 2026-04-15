# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Send letters to neighbours task", :capybara, type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:assessor) { create(:user, :assessor, local_authority: local_authority) }
  let(:application_type) { create(:application_type, :prior_approval) }
  let(:planning_application) {
    create(:planning_application, :from_planx_prior_approval, :with_boundary_geojson, :published, local_authority:, application_type:, agent_email: "agent@example.com", applicant_email: "applicant@example.com")
  }
  let(:slug) { "consultees-neighbours-and-publicity/neighbours/send-letters-to-neighbours" }
  let(:task) { planning_application.case_record.find_task_by_slug_path!(slug) }

  let(:consultation) { planning_application.consultation }
  let(:reference) { planning_application.reference }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("BOPS_ENVIRONMENT", "development").and_return("production")
    travel_to(Time.zone.local(2023, 9, 1, 10))

    sign_in assessor

    visit "/planning_applications/#{planning_application.reference}/#{slug}"
  end

  context "when sending letters" do
    before do
      create(:neighbour, consultation:, source: :manual_add, address: "60-62, Commercial Street, E16LT")
      neighbour = create(:neighbour, consultation:, source: :manual_add, address: "123, Made Up Street, London, W5 67S")
      neighbour_letter = create(:neighbour_letter, neighbour:, status: "submitted", notify_id: "123")

      stub_send_letter(status: 200)
      stub_get_notify_status(notify_id: neighbour_letter.notify_id)

      visit "/planning_applications/#{planning_application.reference}/#{slug}"
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

      expect {
        click_button "Send letters"
        expect(page).to have_content("Letters have been sent to neighbours")
      }.to change(NeighbourLetter, :count).by(2)

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
end
