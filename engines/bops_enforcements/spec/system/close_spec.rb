# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Enforcement close page", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let!(:submission) do
    create(
      :submission,
      :planning_portal,
      local_authority: local_authority,
      request_body: json_fixture_api("examples/odp/v0.7.5/enforcement/breach.json")
    )
  end
  let!(:case_record) { build(:case_record, local_authority:, submission: submission) }
  let!(:enforcement) { create(:enforcement, case_record:) }
  let(:officer) { create(:user, local_authority:) }
  let(:manager) { create(:user, :reviewer, local_authority:) }
  let!(:task) { create(:task, parent: case_record, section: "Check", name: "Test task 1", slug: "test-task-1") }
  let!(:task2) { create(:task, parent: case_record, section: "Check", name: "Test task 2", slug: "test-task-2") }
  let!(:task3) { create(:task, parent: case_record, section: "Investigate", name: "Test task 3", slug: "test-task-3") }

  let(:notify_url) do
    "https://api.notifications.service.gov.uk/v2/notifications"
  end

  before do
    sign_in(officer)
    visit "/enforcements/#{enforcement.reference}/"

    click_link "Close the case"
  end

  context "when manager approval is not required" do
    before do
      choose "Other"
      fill_in "Reason", with: "Because I want to"
      fill_in "Additional comments (optional)", with: "Words words words."
      choose "No, I want to close the case right away without manager review and notify complainant"
    end

    context do
      before do
        click_button "Confirm and submit"
      end

      it "can be closed" do
        expect(page).to have_content("Case successfully closed")

        enforcement.reload
        expect(enforcement.status).to eq("closed")
        expect(enforcement.closed_reason).to eq("Because I want to")
      end

      it "shows an error navigating to tasks" do
        expect(page).to have_content("Case successfully closed")

        visit "/enforcements/#{enforcement.reference}/check-breach-report"
        expect(page).to have_content("You cannot make changes to this case as it has already been closed")
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
        click_button "Confirm and submit"
      end.to have_enqueued_job(BopsEnforcements::SendCloseInvestigationEmailJob).exactly(:once)

      perform_enqueued_jobs
      expect(notify).to have_been_requested
    end
  end

  context "when manager approval is required" do
    before do
      choose "Not expedient to enforce"
      fill_in "Additional comments (optional)", with: "Words words words."
    end

    it "cannot be submitted if approval is not selected" do
      click_button "Confirm and submit"
      expect(page).to have_content("Select an option")
    end

    it "cannot be submitted if choosing no approval needed" do
      choose "No, I want to close the case right away without manager review and notify complainant"
      click_button "Confirm and submit"
      expect(page).to have_content("Manager approval is required to close the case")
    end

    context do
      before do
        choose "Yes, I want to send my recommendation to a manager to review and sign off before the case is closed"
        click_button "Confirm and submit"
      end

      it "can be closed" do
        expect(page).to have_content("Case successfully closed")
        enforcement.reload
        expect(enforcement.status).to eq("requested_closure")
        expect(enforcement.closed_reason).to eq("Not expedient to enforce")
      end

      it "shows an error navigating to tasks" do
        expect(page).to have_content("Case successfully closed")

        visit "/enforcements/#{enforcement.reference}/check-breach-report"
        expect(page).to have_content("You cannot make changes to this case as it has already been closed")
      end

      context "manager actions" do
        before do
          expect(page).to have_content("Case successfully closed")  # waiting
          sign_out officer
          sign_in manager
        end

        it "has the expected landing page content" do
          visit "/enforcements/#{enforcement.reference}"
          expect(page).to have_content("The assigned case officer has recommended to close the case")
        end

        it "has the expected content on the close page" do
          visit "/enforcements/#{enforcement.reference}/close-case"
          expect(page).to have_content "Under council protocol"
          expect(page).to have_content "Close case recommendation Not expedient"
        end

        context "when the manager approves" do
          before do
            visit "/enforcements/#{enforcement.reference}/close-case"
            choose "Yes, close the case and notify complainant"
            click_button "Confirm"
          end

          it "can be closed" do
            expect(page).to have_content("Case successfully closed")

            enforcement.reload
            expect(enforcement.status).to eq("closed")
            expect(enforcement.closed_reason).to eq("Not expedient to enforce")
          end
        end

        context "when the manager disapproves" do
          before do
            visit "/enforcements/#{enforcement.reference}/close-case"
            choose "No, return the case to officer"
            fill_in "Explain to the case officer why the case is being returned", with: "Do it anyway"
            click_button "Confirm"
          end

          it "can be reopened" do
            expect(page).to have_content("Case successfully reopened")

            enforcement.reload
            expect(enforcement.status).to eq("in_validation")
          end
        end
      end
    end

    it "does not send an email" do
      notify = stub_request(:post, "#{notify_url}/email")

      expect do
        click_button "Confirm and submit"
      end.not_to have_enqueued_job(BopsEnforcements::SendCloseInvestigationEmailJob)

      perform_enqueued_jobs
      expect(notify).not_to have_been_requested
    end
  end
end
