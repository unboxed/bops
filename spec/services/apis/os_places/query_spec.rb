# frozen_string_literal: true

require "rails_helper"

RSpec.describe Apis::OsPlaces::Query do
  let(:query) { described_class.new }

  before do
    Rails.configuration.os_vector_tiles_api_key = "testtest"
    stub_os_places_api_request_for("SE220HW")
  end

  describe ".find_addresses" do
    it "initializes a Client object and invokes #call" do
      expect_any_instance_of(Apis::OsPlaces::Client).to receive(:call).with("SE220HW").and_call_original

      described_class.new.find_addresses("SE220HW")
    end
  end
end
