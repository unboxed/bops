# frozen_string_literal: true

require "rails_helper"

RSpec.describe PostApplicationToStagingJob do
  let!(:planning_application) { create(:planning_application, :from_planx) }

  before do
    stub_bops_api_request_for(planning_application.local_authority, planning_application)
  end

  it "calls the query to post to staging" do
    expect_any_instance_of(Apis::Bops::Query).to receive(:post)
      .with(planning_application.local_authority.subdomain, planning_application)
      .and_call_original

    described_class.perform_now(planning_application.local_authority, planning_application)
  end
end
