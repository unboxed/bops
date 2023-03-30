# frozen_string_literal: true

require "rails_helper"

RSpec.describe Apis::Bops::Client do
  let(:client) { described_class.new }
  let(:planning_application) { create(:planning_application) }

  describe "#call" do
    before do
      # allow(ENV).to receive(:fetch).with("STAGING_API_BEARER").and_return("testtesttest")
      allow(ENV).to receive(:fetch).with("STAGING_API_URL").and_return("testtesttest")
    end
    
    it "is successful" do
      allow(ENV).to receive(:fetch).with("STAGING_API_URL").and_return("testtesttest")
      # allow(client).to receive(:call).with(LocalAuthority.first, planning_application).and_return(200)

      expect(client.call(LocalAuthority.first, planning_application).status).to eq(200)
    end
  end
end
