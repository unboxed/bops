# frozen_string_literal: true

require "rails_helper"

RSpec.describe PostApplicationToStagingJob do
  let(:planning_application) { create(:planning_application) }

  before do
    stub_bops_api_request_for(planning_application.local_authority, planning_application)
  end

  context "when there is an ODP submission" do
    before do
      create(:planx_planning_data, params_v2: api_json_fixture("odp/v0.7.0/validPlanningPermission.json"), planning_application:)
    end

    it "calls the query to post to staging" do
      expect_any_instance_of(Apis::Bops::Query).to receive(:post)
        .with(planning_application.local_authority.subdomain, planning_application.params_v2)
        .and_call_original

      described_class.perform_now(planning_application.local_authority, planning_application)
    end
  end

  context "when there is no ODP submission" do
    it "sends an error to AppSignal" do
      expect(Appsignal).to receive(:send_error).with("Unable to find submission data for planning application with id: #{planning_application.id}")

      described_class.perform_now(planning_application.local_authority, planning_application)
    end
  end
end
