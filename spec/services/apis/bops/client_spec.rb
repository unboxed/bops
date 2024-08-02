# frozen_string_literal: true

require "rails_helper"

RSpec.describe Apis::Bops::Client do
  let(:client) { described_class.new }
  let(:planning_application) { create(:planning_application) }

  before do
    create(:planx_planning_data, params_v2: api_json_fixture("odp/v0.7.0/validPlanningPermission.json"), planning_application:)
  end

  describe "#call" do
    it "is successful" do
      Rails.configuration.staging_api_bearer = "testtesttest"
      expect(client.call(planning_application.local_authority.subdomain, planning_application.params_v2).status).to eq(200)
    end
  end
end
