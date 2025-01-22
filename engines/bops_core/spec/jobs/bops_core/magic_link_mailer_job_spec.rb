# frozen_string_literal: true

require "bops_core_helper"

RSpec.describe BopsCore::MagicLinkMailerJob, type: :job do
  let(:consultation) { create(:consultation) }
  let(:consultee) { create(:consultee, consultation:) }
  let(:planning_application) { create(:planning_application, consultation:) }

  it "enqueues the job" do
    expect {
      BopsCore::MagicLinkMailerJob.perform_later(resource: consultee, planning_application:, subdomain: "southwark")
    }.to have_enqueued_job(BopsCore::MagicLinkMailerJob).with(resource: consultee, planning_application:, subdomain: "southwark")
  end

  it "sends the email" do
    expect {
      perform_enqueued_jobs do
        BopsCore::MagicLinkMailerJob.perform_now(resource: consultee, planning_application:, subdomain: "southwark")
      end
    }.to change { ActionMailer::Base.deliveries.count }.by(1)
  end
end
