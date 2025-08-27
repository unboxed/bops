# frozen_string_literal: true

require "rails_helper"

RSpec.describe Apis::Bops::Query do
  let(:planning_application) { create(:planning_application) }

  before do
    create(:planx_planning_data, params_v2: json_fixture_api("examples/odp/v0.7.0/validPlanningPermission.json"), planning_application:)
  end

  describe ".fetch" do
    it "initializes a Client object with planning application audit log and invokes #call" do
      expect_any_instance_of(Apis::Bops::Client).to receive(:call).with(
        planning_application.local_authority.subdomain,
        planning_application.params_v2
      ).and_call_original

      described_class.new.post(planning_application.local_authority.subdomain, planning_application.params_v2)
    end
  end
end
