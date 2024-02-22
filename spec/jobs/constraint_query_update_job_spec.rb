# frozen_string_literal: true

require "rails_helper"

RSpec.describe ConstraintQueryUpdateJob do
  let(:planning_application) { create(:planning_application, :with_boundary_geojson) }
  let(:query_service) { ConstraintQueryUpdateService.new(planning_application:) }
  let(:query) { "POLYGON ((-0.054597 51.537331, -0.054588 51.537287, -0.054453 51.537313, -0.054597 51.537331))" }

  before do
    stub_planx_api_response_for(query).to_return(status: 200, body: "{}")
  end

  around do |example|
    freeze_time { example.run }
  end

  describe "#perform" do
    before do
      allow(ConstraintQueryUpdateService).to receive(:new).and_return(query_service)
      allow(query_service).to receive(:call).and_call_original

      described_class.perform_later(planning_application:)
    end

    context "when the query is successful" do
      before do
        stub_planx_api_response_for(query).to_return(status: 200, body: "{}")
      end

      it "processes the job" do
        expect {
          perform_enqueued_jobs
        }.to change {
          enqueued_jobs.size
        }.from(1).to(0)
      end
    end

    context "when the query times out" do
      before do
        stub_planx_api_response_for(query).to_raise(Faraday::TimeoutError)
      end

      it "enqueues the job to be retried" do
        expect {
          perform_enqueued_jobs
        }.to have_enqueued_job(described_class)
          .with(planning_application:)
          .on_queue("high_priority")
          .at(5.minutes.from_now)
      end

      it "doesn't raise an error when the maximum number of attempts has been exceeded" do
        expect {
          13.times {
            perform_enqueued_jobs
          }
        }.not_to raise_error
      end
    end
  end
end
