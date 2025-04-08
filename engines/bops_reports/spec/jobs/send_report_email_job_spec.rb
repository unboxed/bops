# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsReports::SendReportEmailJob, type: :job do
  let!(:planning_application) { create(:planning_application, :pre_application, user:) }
  let(:user) { create(:user) }

  it "enqueues the job" do
    expect {
      described_class.perform_later(planning_application, user)
    }.to have_enqueued_job(described_class).with(planning_application, user)
  end

  context "when the planning application is a pre-application" do
    it "sends the report email" do
      expect {
        perform_enqueued_jobs do
          described_class.perform_now(planning_application, user)
        end
      }.to change { ActionMailer::Base.deliveries.count }.by(2) # Sends to both applicant / agent emails
    end

    it "creates an audit record" do
      perform_enqueued_jobs do
        described_class.perform_now(planning_application, user)
      end

      audit = planning_application.audits.last
      expect(audit.user).to eq(user)
      expect(audit.activity_type).to eq("pre_application_report_sent")
      expect(audit.audit_comment).to eq("Pre-application report was sent")
    end
  end

  context "when the planning application is not a pre-application" do
    let(:planning_application) { create(:planning_application, user:) }

    it "does not send the report email" do
      expect {
        perform_enqueued_jobs do
          described_class.perform_now(planning_application, user)
        end
      }.not_to change { ActionMailer::Base.deliveries.count }
    end

    it "does not create an audit record" do
      expect {
        perform_enqueued_jobs do
          described_class.perform_now(planning_application, user)
        end
      }.not_to change { planning_application.audits.count }
    end
  end
end
