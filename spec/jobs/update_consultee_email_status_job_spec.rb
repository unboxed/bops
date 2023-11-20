# frozen_string_literal: true

require "rails_helper"

RSpec.describe UpdateConsulteeEmailStatusJob do
  let(:planning_application) { create(:planning_application, :planning_permission) }
  let(:consultation) { planning_application.consultation }

  let(:notify_url) do
    "https://api.notifications.service.gov.uk/v2/notifications/ddc217c4-7f45-47ad-9dab-cb245ec31e55"
  end

  around do |example|
    freeze_time { example.run }
  end

  context "when the email has not been sent yet" do
    let(:consultee) { create(:consultee, :created, consultation:, email_address: "planning@london.gov.uk") }
    let(:consultee_email) { create(:consultee_email, :pending, consultee:) }

    it "doesn't touch the status_updated_at timestamp" do
      expect do
        described_class.perform_now(consultee_email)
      end.not_to change {
        consultee_email.status_updated_at
      }.from(nil)
    end

    it "enqueues another job" do
      expect do
        described_class.perform_now(consultee_email)
      end.to have_enqueued_job(described_class).with(consultee_email).at(5.minutes.from_now)
    end

    it "doesn't change the consultee status from 'sending'" do
      expect do
        described_class.perform_now(consultee_email)
      end.not_to change {
        consultee.reload.status
      }.from("sending")
    end
  end

  context "when the email has been created" do
    let(:consultee) { create(:consultee, :sending, consultation:, email_address: "planning@london.gov.uk") }
    let(:consultee_email) { create(:consultee_email, :created, notify_id: "ddc217c4-7f45-47ad-9dab-cb245ec31e55", consultee:) }

    context "and the Notify API returns an error" do
      before do
        stub_request(:get, notify_url).to_timeout
      end

      it "doesn't change the status" do
        expect do
          described_class.perform_now(consultee_email)
        end.not_to change {
          consultee_email.status
        }.from("created")
      end

      it "doesn't touch the status_updated_at timestamp" do
        expect do
          described_class.perform_now(consultee_email)
        end.not_to change {
          consultee_email.status_updated_at
        }.from(5.minutes.ago)
      end

      it "enqueues another job" do
        expect do
          described_class.perform_now(consultee_email)
        end.to have_enqueued_job(described_class).with(consultee_email).at(5.minutes.from_now)
      end

      it "doesn't change the consultee status from 'sending'" do
        expect do
          described_class.perform_now(consultee_email)
        end.not_to change {
          consultee.reload.status
        }.from("sending")
      end

      it "doesn't change the consultee status from 'sending'" do
        expect do
          described_class.perform_now(consultee_email)
        end.not_to change {
          consultee.reload.status
        }.from("sending")
      end
    end

    context "and the Notify API returns a 'sending' status" do
      before do
        stub_request(:get, notify_url).to_return(
          status: 200,
          headers: {
            "Content-Type" => "application/json"
          },
          body: {
            id: "ddc217c4-7f45-47ad-9dab-cb245ec31e55",
            status: "sending"
          }.to_json
        )
      end

      it "changes the status to 'sending'" do
        expect do
          described_class.perform_now(consultee_email)
        end.to change {
          consultee_email.status
        }.from("created").to("sending")
      end

      it "touches the status_updated_at timestamp" do
        expect do
          described_class.perform_now(consultee_email)
        end.to change {
          consultee_email.status_updated_at
        }.from(5.minutes.ago).to(Time.current)
      end

      it "enqueues another job" do
        expect do
          described_class.perform_now(consultee_email)
        end.to have_enqueued_job(described_class).with(consultee_email).at(5.minutes.from_now)
      end

      it "doesn't change the consultee status from 'sending'" do
        expect do
          described_class.perform_now(consultee_email)
        end.not_to change {
          consultee.reload.status
        }.from("sending")
      end
    end

    context "and the Notify API returns a 'temporary-failure' status" do
      before do
        stub_request(:get, notify_url).to_return(
          status: 200,
          headers: {
            "Content-Type" => "application/json"
          },
          body: {
            id: "ddc217c4-7f45-47ad-9dab-cb245ec31e55",
            status: "temporary-failure"
          }.to_json
        )
      end

      it "changes the status to 'temporary-failure'" do
        expect do
          described_class.perform_now(consultee_email)
        end.to change {
          consultee_email.status
        }.from("created").to("temporary_failure")
      end

      it "touches the status_updated_at timestamp" do
        expect do
          described_class.perform_now(consultee_email)
        end.to change {
          consultee_email.status_updated_at
        }.from(5.minutes.ago).to(Time.current)
      end

      it "enqueues another job" do
        expect do
          described_class.perform_now(consultee_email)
        end.to have_enqueued_job(described_class).with(consultee_email).at(5.minutes.from_now)
      end

      it "changes the consultee status to 'failed'" do
        expect do
          described_class.perform_now(consultee_email)
        end.to change {
          consultee.reload.status
        }.from("sending").to("failed")
      end
    end

    context "and the Notify API returns a 'delivered' status" do
      before do
        stub_request(:get, notify_url).to_return(
          status: 200,
          headers: {
            "Content-Type" => "application/json"
          },
          body: {
            id: "ddc217c4-7f45-47ad-9dab-cb245ec31e55",
            status: "delivered"
          }.to_json
        )
      end

      it "changes the status to 'delivered'" do
        expect do
          described_class.perform_now(consultee_email)
        end.to change {
          consultee_email.status
        }.from("created").to("delivered")
      end

      it "touches the status_updated_at timestamp" do
        expect do
          described_class.perform_now(consultee_email)
        end.to change {
          consultee_email.status_updated_at
        }.from(5.minutes.ago).to(Time.current)
      end

      it "doesn't enqueue another job" do
        expect do
          described_class.perform_now(consultee_email)
        end.not_to have_enqueued_job(described_class).with(consultee_email)
      end

      it "changes the consultee status to 'awaiting_response'" do
        expect do
          described_class.perform_now(consultee_email)
        end.to change {
          consultee.reload.status
        }.from("sending").to("awaiting_response")
      end

      it "touches the consultee email_delivered_at timestamp" do
        expect do
          described_class.perform_now(consultee_email)
        end.to change {
          consultee.reload.email_delivered_at
        }.from(nil).to(Time.current)
      end

      it "touches the consultee last_email_delivered_at timestamp" do
        expect do
          described_class.perform_now(consultee_email)
        end.to change {
          consultee.reload.last_email_delivered_at
        }.from(nil).to(Time.current)
      end

      context "and the message is a resend or reconsultation" do
        let(:consultee) { create(:consultee, :resending, consultation:, email_address: "planning@london.gov.uk") }

        it "changes the consultee status to 'awaiting_response'" do
          expect do
            described_class.perform_now(consultee_email)
          end.to change {
            consultee.reload.status
          }.from("sending").to("awaiting_response")
        end

        it "doesn't touch the consultee email_delivered_at timestamp" do
          expect do
            described_class.perform_now(consultee_email)
          end.not_to change {
            consultee.reload.email_delivered_at
          }.from(7.days.ago)
        end

        it "touches the consultee last_email_delivered_at timestamp" do
          expect do
            described_class.perform_now(consultee_email)
          end.to change {
            consultee.reload.last_email_delivered_at
          }.from(7.days.ago).to(Time.current)
        end
      end
    end

    context "and the Notify API returns a 'permanent-failure' status" do
      before do
        stub_request(:get, notify_url).to_return(
          status: 200,
          headers: {
            "Content-Type" => "application/json"
          },
          body: {
            id: "ddc217c4-7f45-47ad-9dab-cb245ec31e55",
            status: "permanent-failure"
          }.to_json
        )
      end

      it "changes the status to 'permanent_failure'" do
        expect do
          described_class.perform_now(consultee_email)
        end.to change {
          consultee_email.status
        }.from("created").to("permanent_failure")
      end

      it "touches the status_updated_at timestamp" do
        expect do
          described_class.perform_now(consultee_email)
        end.to change {
          consultee_email.status_updated_at
        }.from(5.minutes.ago).to(Time.current)
      end

      it "doesn't enqueue another job" do
        expect do
          described_class.perform_now(consultee_email)
        end.not_to have_enqueued_job(described_class).with(consultee_email)
      end

      it "changes the consultee status to 'failed'" do
        expect do
          described_class.perform_now(consultee_email)
        end.to change {
          consultee.reload.status
        }.from("sending").to("failed")
      end
    end

    context "and the Notify API returns a 'technical-failure' status" do
      before do
        stub_request(:get, notify_url).to_return(
          status: 200,
          headers: {
            "Content-Type" => "application/json"
          },
          body: {
            id: "ddc217c4-7f45-47ad-9dab-cb245ec31e55",
            status: "technical-failure"
          }.to_json
        )
      end

      it "changes the status to 'technical_failure'" do
        expect do
          described_class.perform_now(consultee_email)
        end.to change {
          consultee_email.status
        }.from("created").to("technical_failure")
      end

      it "touches the status_updated_at timestamp" do
        expect do
          described_class.perform_now(consultee_email)
        end.to change {
          consultee_email.status_updated_at
        }.from(5.minutes.ago).to(Time.current)
      end

      it "doesn't enqueue another job" do
        expect do
          described_class.perform_now(consultee_email)
        end.not_to have_enqueued_job(described_class).with(consultee_email)
      end

      it "changes the consultee status to 'failed'" do
        expect do
          described_class.perform_now(consultee_email)
        end.to change {
          consultee.reload.status
        }.from("sending").to("failed")
      end
    end
  end

  context "when the email is sending" do
    let(:consultee) { create(:consultee, :sending, consultation:, email_address: "planning@london.gov.uk") }
    let(:consultee_email) { create(:consultee_email, :sending, notify_id: "ddc217c4-7f45-47ad-9dab-cb245ec31e55", consultee:) }

    context "and the Notify API returns an error" do
      before do
        stub_request(:get, notify_url).to_timeout
      end

      it "doesn't change the status" do
        expect do
          described_class.perform_now(consultee_email)
        end.not_to change {
          consultee_email.status
        }.from("sending")
      end

      it "doesn't touch the status_updated_at timestamp" do
        expect do
          described_class.perform_now(consultee_email)
        end.not_to change {
          consultee_email.status_updated_at
        }.from(5.minutes.ago)
      end

      it "enqueues another job" do
        expect do
          described_class.perform_now(consultee_email)
        end.to have_enqueued_job(described_class).with(consultee_email).at(5.minutes.from_now)
      end

      it "doesn't change the consultee status from 'sending'" do
        expect do
          described_class.perform_now(consultee_email)
        end.not_to change {
          consultee.reload.status
        }.from("sending")
      end
    end

    context "and the Notify API returns a 'sending' status" do
      before do
        stub_request(:get, notify_url).to_return(
          status: 200,
          headers: {
            "Content-Type" => "application/json"
          },
          body: {
            id: "ddc217c4-7f45-47ad-9dab-cb245ec31e55",
            status: "sending"
          }.to_json
        )
      end

      it "doesn't change the status" do
        expect do
          described_class.perform_now(consultee_email)
        end.not_to change {
          consultee_email.status
        }.from("sending")
      end

      it "touches the status_updated_at timestamp" do
        expect do
          described_class.perform_now(consultee_email)
        end.to change {
          consultee_email.status_updated_at
        }.from(5.minutes.ago).to(Time.current)
      end

      it "enqueues another job" do
        expect do
          described_class.perform_now(consultee_email)
        end.to have_enqueued_job(described_class).with(consultee_email).at(5.minutes.from_now)
      end

      it "doesn't change the consultee status from 'sending'" do
        expect do
          described_class.perform_now(consultee_email)
        end.not_to change {
          consultee.reload.status
        }.from("sending")
      end
    end

    context "and the Notify API returns a 'temporary-failure' status" do
      before do
        stub_request(:get, notify_url).to_return(
          status: 200,
          headers: {
            "Content-Type" => "application/json"
          },
          body: {
            id: "ddc217c4-7f45-47ad-9dab-cb245ec31e55",
            status: "temporary-failure"
          }.to_json
        )
      end

      it "changes the status to 'temporary-failure'" do
        expect do
          described_class.perform_now(consultee_email)
        end.to change {
          consultee_email.status
        }.from("sending").to("temporary_failure")
      end

      it "touches the status_updated_at timestamp" do
        expect do
          described_class.perform_now(consultee_email)
        end.to change {
          consultee_email.status_updated_at
        }.from(5.minutes.ago).to(Time.current)
      end

      it "enqueues another job" do
        expect do
          described_class.perform_now(consultee_email)
        end.to have_enqueued_job(described_class).with(consultee_email).at(5.minutes.from_now)
      end

      it "changes the consultee status to 'failed'" do
        expect do
          described_class.perform_now(consultee_email)
        end.to change {
          consultee.reload.status
        }.from("sending").to("failed")
      end
    end

    context "and the Notify API returns a 'delivered' status" do
      before do
        stub_request(:get, notify_url).to_return(
          status: 200,
          headers: {
            "Content-Type" => "application/json"
          },
          body: {
            id: "ddc217c4-7f45-47ad-9dab-cb245ec31e55",
            status: "delivered"
          }.to_json
        )
      end

      it "changes the status to 'delivered'" do
        expect do
          described_class.perform_now(consultee_email)
        end.to change {
          consultee_email.status
        }.from("sending").to("delivered")
      end

      it "touches the status_updated_at timestamp" do
        expect do
          described_class.perform_now(consultee_email)
        end.to change {
          consultee_email.status_updated_at
        }.from(5.minutes.ago).to(Time.current)
      end

      it "doesn't enqueue another job" do
        expect do
          described_class.perform_now(consultee_email)
        end.not_to have_enqueued_job(described_class).with(consultee_email)
      end

      it "changes the consultee status to 'awaiting_response'" do
        expect do
          described_class.perform_now(consultee_email)
        end.to change {
          consultee.reload.status
        }.from("sending").to("awaiting_response")
      end

      it "touches the consultee email_delivered_at timestamp" do
        expect do
          described_class.perform_now(consultee_email)
        end.to change {
          consultee.reload.email_delivered_at
        }.from(nil).to(Time.current)
      end

      it "touches the consultee last_email_delivered_at timestamp" do
        expect do
          described_class.perform_now(consultee_email)
        end.to change {
          consultee.reload.last_email_delivered_at
        }.from(nil).to(Time.current)
      end

      context "and the message is a resend or reconsultation" do
        let(:consultee) { create(:consultee, :resending, consultation:, email_address: "planning@london.gov.uk") }

        it "changes the consultee status to 'awaiting_response'" do
          expect do
            described_class.perform_now(consultee_email)
          end.to change {
            consultee.reload.status
          }.from("sending").to("awaiting_response")
        end

        it "doesn't touch the consultee email_delivered_at timestamp" do
          expect do
            described_class.perform_now(consultee_email)
          end.not_to change {
            consultee.reload.email_delivered_at
          }.from(7.days.ago)
        end

        it "touches the consultee last_email_delivered_at timestamp" do
          expect do
            described_class.perform_now(consultee_email)
          end.to change {
            consultee.reload.last_email_delivered_at
          }.from(7.days.ago).to(Time.current)
        end
      end
    end

    context "and the Notify API returns a 'permanent-failure' status" do
      before do
        stub_request(:get, notify_url).to_return(
          status: 200,
          headers: {
            "Content-Type" => "application/json"
          },
          body: {
            id: "ddc217c4-7f45-47ad-9dab-cb245ec31e55",
            status: "permanent-failure"
          }.to_json
        )
      end

      it "changes the status to 'permanent_failure'" do
        expect do
          described_class.perform_now(consultee_email)
        end.to change {
          consultee_email.status
        }.from("sending").to("permanent_failure")
      end

      it "touches the status_updated_at timestamp" do
        expect do
          described_class.perform_now(consultee_email)
        end.to change {
          consultee_email.status_updated_at
        }.from(5.minutes.ago).to(Time.current)
      end

      it "doesn't enqueue another job" do
        expect do
          described_class.perform_now(consultee_email)
        end.not_to have_enqueued_job(described_class).with(consultee_email)
      end

      it "changes the consultee status to 'failed'" do
        expect do
          described_class.perform_now(consultee_email)
        end.to change {
          consultee.reload.status
        }.from("sending").to("failed")
      end
    end

    context "and the Notify API returns a 'technical-failure' status" do
      before do
        stub_request(:get, notify_url).to_return(
          status: 200,
          headers: {
            "Content-Type" => "application/json"
          },
          body: {
            id: "ddc217c4-7f45-47ad-9dab-cb245ec31e55",
            status: "technical-failure"
          }.to_json
        )
      end

      it "changes the status to 'technical_failure'" do
        expect do
          described_class.perform_now(consultee_email)
        end.to change {
          consultee_email.status
        }.from("sending").to("technical_failure")
      end

      it "touches the status_updated_at timestamp" do
        expect do
          described_class.perform_now(consultee_email)
        end.to change {
          consultee_email.status_updated_at
        }.from(5.minutes.ago).to(Time.current)
      end

      it "doesn't enqueue another job" do
        expect do
          described_class.perform_now(consultee_email)
        end.not_to have_enqueued_job(described_class).with(consultee_email)
      end

      it "changes the consultee status to 'failed'" do
        expect do
          described_class.perform_now(consultee_email)
        end.to change {
          consultee.reload.status
        }.from("sending").to("failed")
      end
    end
  end

  context "when the email has a temporary failure" do
    let(:consultee) { create(:consultee, :failed, consultation:, email_address: "planning@london.gov.uk") }
    let(:consultee_email) { create(:consultee_email, :temporary_failure, notify_id: "ddc217c4-7f45-47ad-9dab-cb245ec31e55", consultee:) }

    context "and the Notify API returns an error" do
      before do
        stub_request(:get, notify_url).to_timeout
      end

      it "doesn't change the status" do
        expect do
          described_class.perform_now(consultee_email)
        end.not_to change {
          consultee_email.status
        }.from("temporary_failure")
      end

      it "doesn't touch the status_updated_at timestamp" do
        expect do
          described_class.perform_now(consultee_email)
        end.not_to change {
          consultee_email.status_updated_at
        }.from(5.minutes.ago)
      end

      it "enqueues another job" do
        expect do
          described_class.perform_now(consultee_email)
        end.to have_enqueued_job(described_class).with(consultee_email).at(5.minutes.from_now)
      end
    end

    context "and the Notify API returns a 'sending' status" do
      before do
        stub_request(:get, notify_url).to_return(
          status: 200,
          headers: {
            "Content-Type" => "application/json"
          },
          body: {
            id: "ddc217c4-7f45-47ad-9dab-cb245ec31e55",
            status: "sending"
          }.to_json
        )
      end

      it "changes the status to 'sending'" do
        expect do
          described_class.perform_now(consultee_email)
        end.to change {
          consultee_email.status
        }.from("temporary_failure").to("sending")
      end

      it "touches the status_updated_at timestamp" do
        expect do
          described_class.perform_now(consultee_email)
        end.to change {
          consultee_email.status_updated_at
        }.from(5.minutes.ago).to(Time.current)
      end

      it "enqueues another job" do
        expect do
          described_class.perform_now(consultee_email)
        end.to have_enqueued_job(described_class).with(consultee_email).at(5.minutes.from_now)
      end
    end

    context "and the Notify API returns a 'temporary-failure' status" do
      before do
        stub_request(:get, notify_url).to_return(
          status: 200,
          headers: {
            "Content-Type" => "application/json"
          },
          body: {
            id: "ddc217c4-7f45-47ad-9dab-cb245ec31e55",
            status: "temporary-failure"
          }.to_json
        )
      end

      it "doesn't change the status from 'temporary-failure'" do
        expect do
          described_class.perform_now(consultee_email)
        end.not_to change {
          consultee_email.status
        }.from("temporary_failure")
      end

      it "touches the status_updated_at timestamp" do
        expect do
          described_class.perform_now(consultee_email)
        end.to change {
          consultee_email.status_updated_at
        }.from(5.minutes.ago).to(Time.current)
      end

      it "enqueues another job" do
        expect do
          described_class.perform_now(consultee_email)
        end.to have_enqueued_job(described_class).with(consultee_email).at(5.minutes.from_now)
      end
    end

    context "and the Notify API returns a 'delivered' status" do
      before do
        stub_request(:get, notify_url).to_return(
          status: 200,
          headers: {
            "Content-Type" => "application/json"
          },
          body: {
            id: "ddc217c4-7f45-47ad-9dab-cb245ec31e55",
            status: "delivered"
          }.to_json
        )
      end

      it "changes the status to 'delivered'" do
        expect do
          described_class.perform_now(consultee_email)
        end.to change {
          consultee_email.status
        }.from("temporary_failure").to("delivered")
      end

      it "touches the status_updated_at timestamp" do
        expect do
          described_class.perform_now(consultee_email)
        end.to change {
          consultee_email.status_updated_at
        }.from(5.minutes.ago).to(Time.current)
      end

      it "doesn't enqueue another job" do
        expect do
          described_class.perform_now(consultee_email)
        end.not_to have_enqueued_job(described_class).with(consultee_email)
      end

      it "changes the consultee status to 'awaiting_response'" do
        expect do
          described_class.perform_now(consultee_email)
        end.to change {
          consultee.reload.status
        }.from("failed").to("awaiting_response")
      end

      it "touches the consultee email_delivered_at timestamp" do
        expect do
          described_class.perform_now(consultee_email)
        end.to change {
          consultee.reload.email_delivered_at
        }.from(nil).to(Time.current)
      end

      it "touches the consultee last_email_delivered_at timestamp" do
        expect do
          described_class.perform_now(consultee_email)
        end.to change {
          consultee.reload.last_email_delivered_at
        }.from(nil).to(Time.current)
      end

      context "and the message is a resend or reconsultation" do
        let(:consultee) { create(:consultee, :resend_failed, consultation:, email_address: "planning@london.gov.uk") }

        it "changes the consultee status to 'awaiting_response'" do
          expect do
            described_class.perform_now(consultee_email)
          end.to change {
            consultee.reload.status
          }.from("failed").to("awaiting_response")
        end

        it "doesn't touch the consultee email_delivered_at timestamp" do
          expect do
            described_class.perform_now(consultee_email)
          end.not_to change {
            consultee.reload.email_delivered_at
          }.from(7.days.ago)
        end

        it "touches the consultee last_email_delivered_at timestamp" do
          expect do
            described_class.perform_now(consultee_email)
          end.to change {
            consultee.reload.last_email_delivered_at
          }.from(7.days.ago).to(Time.current)
        end
      end
    end

    context "and the Notify API returns a 'permanent-failure' status" do
      before do
        stub_request(:get, notify_url).to_return(
          status: 200,
          headers: {
            "Content-Type" => "application/json"
          },
          body: {
            id: "ddc217c4-7f45-47ad-9dab-cb245ec31e55",
            status: "permanent-failure"
          }.to_json
        )
      end

      it "changes the status to 'permanent_failure'" do
        expect do
          described_class.perform_now(consultee_email)
        end.to change {
          consultee_email.status
        }.from("temporary_failure").to("permanent_failure")
      end

      it "touches the status_updated_at timestamp" do
        expect do
          described_class.perform_now(consultee_email)
        end.to change {
          consultee_email.status_updated_at
        }.from(5.minutes.ago).to(Time.current)
      end

      it "doesn't enqueue another job" do
        expect do
          described_class.perform_now(consultee_email)
        end.not_to have_enqueued_job(described_class).with(consultee_email)
      end

      it "doesn't change the consultee status from 'failed'" do
        expect do
          described_class.perform_now(consultee_email)
        end.not_to change {
          consultee.reload.status
        }.from("failed")
      end
    end

    context "and the Notify API returns a 'technical-failure' status" do
      before do
        stub_request(:get, notify_url).to_return(
          status: 200,
          headers: {
            "Content-Type" => "application/json"
          },
          body: {
            id: "ddc217c4-7f45-47ad-9dab-cb245ec31e55",
            status: "technical-failure"
          }.to_json
        )
      end

      it "changes the status to 'technical_failure'" do
        expect do
          described_class.perform_now(consultee_email)
        end.to change {
          consultee_email.status
        }.from("temporary_failure").to("technical_failure")
      end

      it "touches the status_updated_at timestamp" do
        expect do
          described_class.perform_now(consultee_email)
        end.to change {
          consultee_email.status_updated_at
        }.from(5.minutes.ago).to(Time.current)
      end

      it "doesn't enqueue another job" do
        expect do
          described_class.perform_now(consultee_email)
        end.not_to have_enqueued_job(described_class).with(consultee_email)
      end

      it "doesn't change the consultee status from 'failed'" do
        expect do
          described_class.perform_now(consultee_email)
        end.not_to change {
          consultee.reload.status
        }.from("failed")
      end
    end
  end

  context "when the email has been delivered" do
    let(:consultee) { create(:consultee, :consulted, consultation:, email_address: "planning@london.gov.uk") }
    let(:consultee_email) { create(:consultee_email, :delivered, consultee:) }

    it "doesn't touch the status_updated_at timestamp" do
      expect do
        described_class.perform_now(consultee_email)
      end.not_to change {
        consultee_email.status_updated_at
      }.from(5.minutes.ago)
    end

    it "doesn't enqueue another job" do
      expect do
        described_class.perform_now(consultee_email)
      end.not_to have_enqueued_job(described_class).with(consultee_email)
    end
  end

  context "when the email has had a technical failure" do
    let(:consultee) { create(:consultee, :failed, consultation:, email_address: "planning@london.gov.uk") }
    let(:consultee_email) { create(:consultee_email, :technical_failure, consultee:) }

    it "doesn't touch the status_updated_at timestamp" do
      expect do
        described_class.perform_now(consultee_email)
      end.not_to change {
        consultee_email.status_updated_at
      }.from(5.minutes.ago)
    end

    it "doesn't enqueue another job" do
      expect do
        described_class.perform_now(consultee_email)
      end.not_to have_enqueued_job(described_class).with(consultee_email)
    end

    it "doesn't change the consultee status from 'failed'" do
      expect do
        described_class.perform_now(consultee_email)
      end.not_to change {
        consultee.reload.status
      }.from("failed")
    end
  end

  context "when the email has permanently failed" do
    let(:consultee) { create(:consultee, :failed, consultation:, email_address: "planning@london.gov.uk") }
    let(:consultee_email) { create(:consultee_email, :permanent_failure, consultee:) }

    it "doesn't touch the status_updated_at timestamp" do
      expect do
        described_class.perform_now(consultee_email)
      end.not_to change {
        consultee_email.status_updated_at
      }.from(5.minutes.ago)
    end

    it "doesn't enqueue another job" do
      expect do
        described_class.perform_now(consultee_email)
      end.not_to have_enqueued_job(described_class).with(consultee_email)
    end

    it "doesn't change the consultee status from 'failed'" do
      expect do
        described_class.perform_now(consultee_email)
      end.not_to change {
        consultee.reload.status
      }.from("failed")
    end
  end
end
