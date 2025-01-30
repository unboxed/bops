# frozen_string_literal: true

require "bops_core_helper"

RSpec.describe BopsCore::MagicLinkMailerJob, type: :job do
  let(:consultation) { create(:consultation) }
  let(:consultee) { create(:consultee, consultation:) }
  let(:planning_application) { create(:planning_application, consultation:) }

  it "enqueues the job" do
    expect {
      BopsCore::MagicLinkMailerJob.perform_later(resource: consultee, planning_application:)
    }.to have_enqueued_job(BopsCore::MagicLinkMailerJob).with(resource: consultee, planning_application:)
  end

  it "updates the magic link last sent at time" do
    travel_to("2025-01-30")

    expect {
      perform_enqueued_jobs do
        BopsCore::MagicLinkMailerJob.perform_now(resource: consultee, planning_application:)
      end
    }.to change { consultee.magic_link_last_sent_at }.from(nil).to("2025-01-30".to_datetime)
  end

  it "sends the email" do
    expect {
      perform_enqueued_jobs do
        BopsCore::MagicLinkMailerJob.perform_now(resource: consultee, planning_application:)
      end
    }.to change { ActionMailer::Base.deliveries.count }.by(1)
  end
end
