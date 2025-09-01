# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Start investigation", type: :system do
  let(:local_authority) { create(:local_authority, :default, feedback_email: "feedback@southwark.gov.uk") }
  let(:submission) { create(:submission, :enforcement) }
  let(:case_record) { build(:case_record, local_authority:, user:, submission:) }
  let(:enforcement) { create(:enforcement, case_record:) }
  let(:user) { create(:user, local_authority:) }
  let(:notify_url) do
    "https://api.notifications.service.gov.uk/v2/notifications"
  end
  let!(:assessor) do
    create(
      :user,
      :assessor,
      local_authority:,
      name: "Jane Smith",
      email: "jane.smith@southwark.gov.uk"
    )
  end

  before do
    sign_in user
    visit "/cases/#{enforcement.case_record.id}/check-breach-report"
    click_link "Start investigation and notify complainant"
  end

  it "displays the correct details" do
    within("#case-details") do
      expect(page).to have_content("Case reference #{case_record.id}")
      expect(page).to have_content(enforcement.address)
      expect(page).to have_selector(".govuk-tag", text: "Not started")
      expect(page).to have_content(enforcement.description)
    end

    expect(page).to have_content("Notification to be sent to complainant - Ebenezer Scrooge (scrooge@waltdisney.com)")

    find("span", text: "View email template").click
    expect(page).to have_content("Enforcement case reference number: #{case_record.id}")
    expect(page).to have_content("Thank you for contacting the Planning Enforcement Team.")
    expect(page).to have_content("Should you have any queries please contact me via email #{user.email}")

    expect(page).to have_link("Back")
  end

  it "I can assign a user to the case record" do
    case_record.update(user: nil)

    visit "/cases/#{enforcement.case_record.id}/check-breach-report"
    click_link "Start investigation and notify complainant"

    expect(page).to have_content("No case officer has been assigned yet.")

    find("span", text: "View email template").click
    expect(page).to have_content("Should you have any queries please contact me via email feedback@southwark.gov.uk")

    click_link "Change"

    select("Jane Smith")
    click_button("Confirm")

    expect(page).to have_content("Assigned to: Jane Smith")
    click_link "Check breach report"
    click_link "Start investigation and notify complainant"
    expect(page).to have_content("The case is currently assigned to: Jane Smith")

    find("span", text: "View email template").click
    expect(page).to have_content("Should you have any queries please contact me via email jane.smith@southwark.gov.uk")

    click_button "Start investigation"
    expect(page).to have_content("Investigation successfully started and complainant notified")
  end

  it "I can start the investigation" do
    expect do
      click_button "Start investigation"
      expect(page).to have_content("Investigation successfully started and complainant notified")
    end.to have_enqueued_job(BopsEnforcements::SendStartInvestigationEmailJob).exactly(:once)

    external = stub_request(:post, "#{notify_url}/email")
      .with(body: hash_including(
        {
          email_address: enforcement.complainant.email,
          email_reply_to_id: "4485df6f-a728-41ed-bc46-cdb2fc6789aa",
          personalisation: hash_including(
              "body" => a_string_starting_with("Enforcement case reference number: #{case_record.id}")
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

    within("#started-date") do
      expect(page).to have_content(Date.current.to_fs)
    end

    within("#Check-section") do
      expect(page).to have_content("Completed")
    end

    click_link "Check breach report"
    within(".govuk-task-list") do
      expect(page).to have_content("Completed")
    end

    click_link "Start investigation and notify complainant"
    expect(page).to have_content("Notification was sent to complainant")

    expect(page).to have_selector(".govuk-tag", text: "Under investigation")
    expect(enforcement.reload.status).to eq("under_investigation")
    expect(page).to have_content("The investigation has already been started.")
  end
end
