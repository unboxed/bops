# frozen_string_literal: true

require "rails_helper"

RSpec.describe Apis::OsPlaces::Client do
  let(:client) { described_class.new }

  before do
    Rails.configuration.os_vector_tiles_api_key = "testtest"
    stub_os_places_api_request_for("SE220HW")
  end

  describe "#call" do
    it "is successful" do
      expect(client.call("SE220HW").status).to eq(200)
    end
  end
end
