# frozen_string_literal: true

require "rails_helper"

RSpec.describe EnqueueUpdateConsulteeEmailStatusJob do
  let(:planning_application) { create(:planning_application, :planning_permission) }
  let(:consultation) { planning_application.consultation }

  let(:consultee_1) { create(:consultee, :sending, consultation:) }
  let(:consultee_2) { create(:consultee, :sending, consultation:) }
  let(:consultee_3) { create(:consultee, :awaiting_response, consultation:) }
  let(:consultee_4) { create(:consultee, :sending, consultation:) }

  let!(:consultee_email_1) { create(:consultee_email, :created, consultee: consultee_1, status_updated_at: 1.hour.ago) }
  let!(:consultee_email_2) { create(:consultee_email, :created, consultee: consultee_2, status_updated_at: 30.minutes.ago) }
  let!(:consultee_email_3) { create(:consultee_email, :delivered, consultee: consultee_3, status_updated_at: 30.minutes.ago) }
  let!(:consultee_email_4) { create(:consultee_email, :created, consultee: consultee_4, status_updated_at: 5.minutes.ago) }

  let(:job_class) { UpdateConsulteeEmailStatusJob }

  it "Enqueues update status jobs for emails that appear to have been dropped" do
    described_class.perform_now

    expect(job_class).to have_been_enqueued.with(consultee_email_1)
    expect(job_class).to have_been_enqueued.with(consultee_email_2)
    expect(job_class).not_to have_been_enqueued.with(consultee_email_3)
    expect(job_class).not_to have_been_enqueued.with(consultee_email_4)
  end
end
