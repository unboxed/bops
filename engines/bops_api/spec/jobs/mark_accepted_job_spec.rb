# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::MarkAcceptedJob, type: :job do
  around do |example|
    freeze_time { example.run }
  end

  context "when the application is pending" do
    let(:planning_application) { create(:planning_application, :pending) }

    context "and the queue is not empty" do
      let(:queue) { instance_double(Sidekiq::Queue) }

      before do
        expect(Sidekiq::Queue).to receive(:new).with("submissions").and_return(queue)
        expect(queue).to receive(:size).and_return(5)
      end

      it "schedules the job to be retried in 5 minutes" do
        expect {
          described_class.perform_now(planning_application)
        }.to have_enqueued_job(described_class).with(planning_application).at(5.minutes.from_now)
      end
    end

    context "and the queue is empty" do
      let(:queue) { instance_double(Sidekiq::Queue) }

      before do
        expect(Sidekiq::Queue).to receive(:new).with("submissions").and_return(queue)
        expect(queue).to receive(:size).and_return(0)
      end

      it "doesn't schedule the job to be retried" do
        expect {
          described_class.perform_now(planning_application)
        }.not_to have_enqueued_job(described_class).with(planning_application)
      end

      it "changes the application status to 'not_started'" do
        expect {
          described_class.perform_now(planning_application)
        }.to change(planning_application, :status).from("pending").to("not_started")
      end
    end
  end

  context "when the application has already been accepted" do
    let(:planning_application) { create(:planning_application, :not_started) }
    let(:queue) { instance_double(Sidekiq::Queue) }

    before do
      expect(Sidekiq::Queue).to receive(:new).with("submissions").and_return(queue)
      expect(queue).to receive(:size).and_return(0)
    end

    it "doesn't schedule the job to be retried" do
      expect {
        described_class.perform_now(planning_application)
      }.not_to have_enqueued_job(described_class).with(planning_application)
    end

    it "doesn't change the application status" do
      expect {
        described_class.perform_now(planning_application)
      }.not_to change(planning_application, :status)
    end
  end
end
