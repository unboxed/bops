# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Send letters to neighbours", js: true do
  let!(:api_user) { create(:api_user, name: "PlanX") }
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application, local_authority: default_local_authority, api_user:, agent_email: "agent@example.com", applicant_email: "applicant@example.com", make_public: true)
  end

  before do
    ENV["OS_VECTOR_TILES_API_KEY"] = "testtest"
    allow_any_instance_of(Faraday::Connection).to receive(:get).and_return(instance_double("response", status: 200, body: "some data")) # rubocop:disable RSpec/VerifiedDoubleReference
    allow_any_instance_of(Apis::OsPlaces::Query).to receive(:get).and_return(Faraday.new.get)

    sign_in assessor
    visit planning_application_path(planning_application)
  end

  it "displays the planning application address, reference, and addresses submitted by applicant" do
    expect(page).to have_content("Publicity")

    click_link "Send letters to neighbours"

    expect(page).to have_content("Send letters to neighbours")

    expect(page).to have_content(planning_application.full_address)
    expect(page).to have_content(planning_application.reference)

    map_selector = find("my-map")
    expect(map_selector["latitude"]).to eq(planning_application.latitude)
    expect(map_selector["longitude"]).to eq(planning_application.longitude)
    expect(map_selector["showMarker"]).to eq("true")

    expect(page).to have_content("Neighbours submitted by applicant")
    expect(page).to have_content("London, 80 Underhill Road, SE22 0QU")
    expect(page).to have_content("London, 78 Underhill Road, SE22 0QU")
  end

  it "allows me to add addresses" do
    click_link "Send letters to neighbours"

    fill_in "Add neighbours by address", with: "60-62 Commercial Street"
    # # Something weird is happening with the javascript, so having to double click for it to register
    # # This doesn't happen in "real life"
    page.find(:xpath, "//input[@value='Add neighbour']").click.click

    expect(page).to have_content("60-62 Commercial Street")

    fill_in "Add neighbours by address", with: "60-61 Commercial Road"
    page.find(:xpath, "//input[@value='Add neighbour']").click.click

    expect(page).to have_content("60-61 Commercial Road")

    expect(page).not_to have_content("Contacted neighbours")
  end

  it "allows me to edit addresses" do
    click_link "Send letters to neighbours"

    fill_in "Add neighbours by address", with: "60-62 Commercial Street"
    page.find(:xpath, "//input[@value='Add neighbour']").click.click

    expect(page).to have_content("60-62 Commercial Street")

    click_link "Edit"

    fill_in "Address", with: "60-62 Commercial Road"
    click_button "Save"

    expect(page).to have_content("60-62 Commercial Road")
  end

  it "allows me to delete addresses" do
    click_link "Send letters to neighbours"

    fill_in "Add neighbours by address", with: "60-62 Commercial Street"
    page.find(:xpath, "//input[@value='Add neighbour']").click.click

    expect(page).to have_content("60-62 Commercial Street")

    click_link "Remove"

    expect(page).not_to have_content("60-62 Commercial Street")
  end

  context "when sending letters" do
    before do
      travel_to(Time.zone.local(2023, 9, 1, 10))
      sign_in assessor
      visit planning_application_path(planning_application)

      consultation = create(:consultation, planning_application:)
      neighbour = create(:neighbour, consultation:)
      neighbour_letter = create(:neighbour_letter, neighbour:, status: "submitted", notify_id: "123")

      stub_send_letter(status: 200)
      stub_get_notify_status(notify_id: neighbour_letter.notify_id)
    end

    it "successfully sends letters to the neighbours and a copy of the letter to the applicant" do
      expect(PlanningApplicationMailer).to receive(:neighbour_consultation_letter_copy_mail).with(planning_application, "agent@example.com").and_call_original
      expect(PlanningApplicationMailer).to receive(:neighbour_consultation_letter_copy_mail).with(planning_application, "applicant@example.com").and_call_original

      sign_in assessor
      visit planning_application_path(planning_application)

      click_link "Send letters to neighbours"

      fill_in "Add neighbours by address", with: "60-62 Commercial Street"
      # # Something weird is happening with the javascript, so having to double click for it to register
      # # This doesn't happen in "real life"
      page.find(:xpath, "//input[@value='Add neighbour']").click.click

      expect(page).to have_content("60-62 Commercial Street")

      expect(page).to have_content("Public consultation")
      expect(page).to have_content("Application received: #{planning_application.received_at.to_fs(:day_month_year_slashes)}")

      fill_in "Add neighbours by address", with: "60-61 Commercial Road"
      page.find(:xpath, "//input[@value='Add neighbour']").click.click

      expect(page).to have_content("A copy of the letter will also be sent by email to the applicant.")
      click_button "Print and send letters"
      expect(page).to have_content("Letters have been sent to neighbours and a copy of the letter has been sent to the applicant.")

      expect(planning_application.consultation.reload.letter_copy_sent_at).to eq(Time.zone.local(2023, 9, 1, 10))

      expect(NeighbourLetter.last.text).to include("We are writing to notify you that we have received a prior approval application for a larger extension at the address:")

      # View audit log
      visit planning_application_audits_path(planning_application)
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
      visit planning_application_path(planning_application)

      click_link "Send letters to neighbours"

      fill_in "Add neighbours by address", with: "60-62 Commercial Street"
      # # Something weird is happening with the javascript, so having to double click for it to register
      # # This doesn't happen in "real life"
      page.find(:xpath, "//input[@value='Add neighbour']").click.click

      expect(page).to have_content("60-62 Commercial Street")

      fill_in "Add neighbours by address", with: "60-61 Commercial Road"
      page.find(:xpath, "//input[@value='Add neighbour']").click.click

      fill_in "Neighbour letter preview", with: "This is some content I'm putting in"
      click_button "Print and send letters"
      expect(page).to have_content("Letters have been sent to neighbours and a copy of the letter has been sent to the applicant.")

      expect(planning_application.consultation.reload.letter_copy_sent_at).to eq(Time.zone.local(2023, 9, 1, 10))

      expect(NeighbourLetter.last.text).to eq("This is some content I'm putting in")

      expect(PlanningApplicationMailer.neighbour_consultation_letter_copy_mail(planning_application, planning_application.agent_email).body)
        .to include("This is some content I'm putting in")
    end

    context "when planning application has not been made public on the BoPS Public Portal" do
      let!(:planning_application) do
        create(:planning_application, local_authority: default_local_authority, make_public: false)
      end

      it "prevents me sending letters and displays an alert" do
        expect(LetterSendingService).not_to receive(:new)

        sign_in assessor
        visit planning_application_path(planning_application)
        click_link "Send letters to neighbours"

        fill_in "Add neighbours by address", with: "60-62 Commercial Street"
        page.find(:xpath, "//input[@value='Add neighbour']").click.click

        click_button "Print and send letters"

        within(".govuk-error-summary__body") do
          expect(page).to have_content("The planning application must be made public on the BoPS Public Portal before you can send letters to neighbours.")
          expect(page).to have_link("made public on the BoPS Public Portal", href: make_public_planning_application_path(planning_application))
        end
      end
    end
  end

  it "shows the status of letters that have been sent" do
    consultation = create(:consultation, planning_application:)
    neighbour = create(:neighbour, consultation:)
    neighbour_letter = create(:neighbour_letter, neighbour:, status: "submitted", notify_id: "123")

    visit current_path
    stub_get_notify_status(notify_id: neighbour_letter.notify_id)

    click_link "Send letters to neighbours"

    expect(page).to have_content("Contacted neighbours")
    expect(page).to have_content(neighbour.address)
    expect(page).to have_content("Posted")

    fill_in "Add neighbours by address", with: "60-62 Commercial Street"
    page.find(:xpath, "//input[@value='Add neighbour']").click.click

    expect(page).to have_content("60-62 Commercial Street")
  end

  describe "showing the status on the dashboard" do
    let(:consultation) { create(:consultation, planning_application:) }

    before do
      sign_in assessor
    end

    context "when there are no letters" do
      it "shows 'not started'" do
        visit planning_application_path(planning_application)
        expect(page).to have_content "Send letters to neighbours Not started"
      end
    end

    context "when there are only successful letters" do
      before do
        neighbour = create(:neighbour, consultation:)
        create(:neighbour_letter, neighbour:, status: "submitted", notify_id: "123")
      end

      it "shows 'completed'" do
        visit planning_application_path(planning_application)
        expect(page).to have_content "Send letters to neighbours Completed"
      end
    end

    context "when there are failed letters" do
      before do
        neighbour1 = create(:neighbour, consultation:)
        neighbour2 = create(:neighbour, consultation:)
        create(:neighbour_letter, neighbour: neighbour1, status: "submitted", notify_id: "123")
        create(:neighbour_letter, neighbour: neighbour2, status: "rejected", notify_id: "123")
      end

      it "shows 'failed'" do
        visit planning_application_path(planning_application)
        expect(page).to have_content "Send letters to neighbours Failed"
      end
    end
  end
end
