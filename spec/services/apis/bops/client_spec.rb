# frozen_string_literal: true

require "rails_helper"

RSpec.describe Apis::Bops::Client do
  let(:client) { described_class.new }
  let(:planning_application) { create(:planning_application, :from_planx) }

  describe "#call" do
    it "is successful" do
      Rails.configuration.staging_api_bearer = "testtesttest"

      expect(client.call(planning_application.local_authority.subdomain, planning_application).status).to eq(200)
    end
  end
end
