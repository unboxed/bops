# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Enforcement close page", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let!(:submission) do
    create(
      :submission,
      local_authority: local_authority,
      request_body: json_fixture_api("examples/odp/v0.7.5/enforcement/breach.json")
    )
  end
  let!(:case_record) { build(:case_record, local_authority:, submission: submission) }
  let!(:enforcement) { create(:enforcement, case_record:) }
  let(:user) { create(:user, local_authority:) }
  let!(:task) { create(:task, parent: case_record, section: "Check", name: "Test task 1", slug: "test-task-1") }
  let!(:task2) { create(:task, parent: case_record, section: "Check", name: "Test task 2", slug: "test-task-2") }
  let!(:task3) { create(:task, parent: case_record, section: "Investigate", name: "Test task 3", slug: "test-task-3") }

  let(:notify_url) do
    "https://api.notifications.service.gov.uk/v2/notifications"
  end

  before do
    sign_in(user)
    visit "/enforcements/#{enforcement.case_record.id}/"

    click_link "Close case"
    choose "Other"
    fill_in "Reason", with: "Because I want to"
    fill_in "Reason for closing", with: "Words words words."
  end

  context do
    before do
      click_button "Close case"
      enforcement.reload
    end

    it "can be closed", :capybara do
      expect(page).to have_content("Case successfully closed")
      expect(enforcement.status).to eq("closed")
      expect(enforcement.closed_reason).to eq("Because I want to")
    end

    it "shows an error navigating to tasks", :capybara do
      visit "/cases/#{enforcement.case_record.id}/check-breach-report"

      expect(page).to have_content("You cannot make changes to this case as it has already been closed")
    end

    it "shows the correct grouping of tasks", capybara: true do
      visit "/enforcements/#{enforcement.case_record.id}/"

      within("#enforcement-tasks") do
        expect(page).to have_selector("h2", count: 6)
        h2s = all("h2", count: 6)

        expect(h2s[0]).to have_text("Check")
        within("#Check-section") do
          lis = all("li", count: 3)
          expect(lis[0]).to have_text("Check breach report")
          expect(lis[1]).to have_text(task.name)
          expect(lis[2]).to have_text(task2.name)
        end

        expect(h2s[1]).to have_text("Investigate")
        within("#Investigate-section") do
          lis = all("li", count: 2)
          expect(lis[0]).to have_text("Investigate and decide")
          expect(lis[1]).to have_text(task3.name)
        end

        expect(h2s[2]).to have_text("Review")
        within("#Review-section") do
          expect(page).to have_selector("li", text: "Review recommendation")
        end

        expect(h2s[4]).to have_text("Appeal")
        within("#Appeal-section") do
          lis = all("li", count: 1)
          expect(lis[0]).to have_text("Process an appeal")
        end
      end
    end
  end

  it "sends an email when closing" do
    notify = stub_request(:post, "#{notify_url}/email")
      .with(body: hash_including(
        {
          personalisation: hash_including(
            "body" => a_string_matching(/\n- Because I want to\n- Words words words.\n\n/)
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

    expect do
      click_button "Close case"
    end.to have_enqueued_job(BopsEnforcements::SendCloseInvestigationEmailJob).exactly(:once)

    perform_enqueued_jobs
    expect(notify).to have_been_requested
  end
end
