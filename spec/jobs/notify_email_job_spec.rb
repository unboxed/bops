# frozen_string_literal: true

require "rails_helper"

RSpec.describe NotifyEmailJob do
  let(:notify_url) do
    "https://api.notifications.service.gov.uk/v2/notifications/email"
  end

  shared_examples "a notify email job" do
    describe "error handling" do
      around do |example|
        freeze_time { example.run }
      end

      context "when there is a deserialization error" do
        let(:model) { arguments.first.class }
        let(:exception_class) { ActiveJob::DeserializationError }

        before do
          allow(model).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
        end

        it "notifies Appsignal of the error" do
          expect(Appsignal).to receive(:send_exception).with(an_instance_of(exception_class))

          perform_enqueued_jobs do
            described_class.perform_later(*arguments)
          end
        end

        it "doesn't reschedule the job" do
          expect do
            described_class.perform_now(*arguments)
          end.not_to have_enqueued_job(described_class)
        end
      end

      context "when GOV.UK Notify is down" do
        let(:exception_class) { Net::OpenTimeout }

        before do
          stub_request(:post, notify_url).to_timeout
        end

        it "doesn't notify Appsignal of the error" do
          expect(Appsignal).not_to receive(:send_exception).with(an_instance_of(exception_class))
          described_class.perform_now(*arguments)
        end

        it "reschedules the job for an hour later" do
          expect do
            described_class.perform_now(*arguments)
          end.to have_enqueued_job(described_class).with(*arguments).at(1.hour.from_now)
        end
      end

      context "when GOV.UK Notify is returning a 500 error" do
        let(:exception_class) { Notifications::Client::ServerError }

        before do
          stub_request(:post, notify_url).to_return(
            status: 500,
            headers: {
              "Content-Type" => "application/json"
            },
            body: {
              errors: [
                { error: "Exception", message: "Internal server error" }
              ]
            }.to_json
          )
        end

        it "doesn't notify Appsignal of the error" do
          expect(Appsignal).not_to receive(:send_exception).with(an_instance_of(exception_class))
          described_class.perform_now(*arguments)
        end

        it "reschedules the job for an hour later" do
          expect do
            described_class.perform_now(*arguments)
          end.to have_enqueued_job(described_class).with(*arguments).at(1.hour.from_now)
        end
      end

      context "when GOV.UK Notify is returning a 400 error" do
        let(:exception_class) { Notifications::Client::BadRequestError }

        before do
          stub_request(:post, notify_url).to_return(
            status: 400,
            headers: {
              "Content-Type" => "application/json"
            },
            body: {
              errors: [
                { error: "BadRequestError", message: "Can't send to this recipient using a team-only API key" }
              ]
            }.to_json
          )
        end

        it "notifies Appsignal of the error" do
          expect(Appsignal).to receive(:send_exception).with(an_instance_of(exception_class))
          described_class.perform_now(*arguments)
        end

        it "reschedules the job for 24 hours later" do
          expect do
            described_class.perform_now(*arguments)
          end.to have_enqueued_job(described_class).with(*arguments).at(24.hours.from_now)
        end
      end

      context "when GOV.UK Notify is returning a 403 error" do
        let(:exception_class) { Notifications::Client::AuthError }

        before do
          stub_request(:post, notify_url).to_return(
            status: 403,
            headers: {
              "Content-Type" => "application/json"
            },
            body: {
              errors: [
                { error: "AuthError", message: "Invalid token: API key not found" }
              ]
            }.to_json
          )
        end

        it "notifies Appsignal of the error" do
          expect(Appsignal).to receive(:send_exception).with(an_instance_of(exception_class))
          described_class.perform_now(*arguments)
        end

        it "reschedules the job for 24 hours later" do
          expect do
            described_class.perform_now(*arguments)
          end.to have_enqueued_job(described_class).with(*arguments).at(24.hours.from_now)
        end
      end

      context "when GOV.UK Notify is returning a 404 error" do
        let(:exception_class) { Notifications::Client::NotFoundError }

        before do
          stub_request(:post, notify_url).to_return(
            status: 404,
            headers: {
              "Content-Type" => "application/json"
            },
            body: {
              errors: [
                { error: "NotFoundError", message: "Not Found" }
              ]
            }.to_json
          )
        end

        it "notifies Appsignal of the error" do
          expect(Appsignal).to receive(:send_exception).with(an_instance_of(exception_class))
          described_class.perform_now(*arguments)
        end

        it "reschedules the job for 24 hours later" do
          expect do
            described_class.perform_now(*arguments)
          end.to have_enqueued_job(described_class).with(*arguments).at(24.hours.from_now)
        end
      end

      context "when GOV.UK Notify is returning an unknown 4XX error" do
        let(:exception_class) { Notifications::Client::ClientError }

        before do
          stub_request(:post, notify_url).to_return(
            status: 408,
            headers: {
              "Content-Type" => "application/json"
            },
            body: {
              errors: [
                { error: "RequestTimeoutError", message: "Request Timeout" }
              ]
            }.to_json
          )
        end

        it "notifies Appsignal of the error" do
          expect(Appsignal).to receive(:send_exception).with(an_instance_of(exception_class))
          described_class.perform_now(*arguments)
        end

        it "reschedules the job for 24 hours later" do
          expect do
            described_class.perform_now(*arguments)
          end.to have_enqueued_job(described_class).with(*arguments).at(24.hours.from_now)
        end
      end

      context "when the rate limit is exceeded" do
        let(:exception_class) { Notifications::Client::RateLimitError }

        before do
          stub_request(:post, notify_url).to_return(
            status: 429,
            headers: {
              "Content-Type" => "application/json"
            },
            body: {
              errors: [
                { error: "RateLimitError", message: "Exceeded rate limit for key type LIVE of 3000 requests per 60 seconds" }
              ]
            }.to_json
          )
        end

        it "doesn't notify Appsignal of the error" do
          expect(Appsignal).not_to receive(:send_exception).with(an_instance_of(exception_class))
          described_class.perform_now(*arguments)
        end

        it "reschedules the job for 5 minutes later" do
          expect do
            described_class.perform_now(*arguments)
          end.to have_enqueued_job(described_class).with(*arguments).at(5.minutes.from_now)
        end
      end

      context "when the daily message limit is exceeded" do
        let(:exception_class) { Notifications::Client::RateLimitError }

        before do
          stub_request(:post, notify_url).to_return(
            status: 429,
            headers: {
              "Content-Type" => "application/json"
            },
            body: {
              errors: [
                { error: "TooManyRequestsError", message: "Exceeded send limits (250,000) for today" }
              ]
            }.to_json
          )
        end

        it "doesn't notify Appsignal of the error" do
          expect(Appsignal).not_to receive(:send_exception).with(an_instance_of(exception_class))
          described_class.perform_now(*arguments)
        end

        it "reschedules the job for midnight" do
          expect do
            described_class.perform_now(*arguments)
          end.to have_enqueued_job(described_class).with(*arguments).at(Date.tomorrow.beginning_of_day)
        end
      end
    end
  end

  describe "subclasses" do
    describe SendConsulteeEmailJob do
      let(:planning_application) { create(:planning_application, :planning_permission) }
      let(:consultation) { planning_application.consultation }
      let(:consultee) { create(:consultee, consultation:, email_address: "planning@london.gov.uk") }
      let(:consultee_email) { create(:consultee_email, consultee:) }
      let(:arguments) { [consultee_email] }

      it_behaves_like "a notify email job"
    end
  end
end
