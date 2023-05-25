# frozen_string_literal: true

require "rails_helper"

RSpec.describe Apis::OsPlaces::Query do
  let(:query) { described_class.new }

  describe ".get" do
    it "initializes a Client object and invokes #call" do
      expect_any_instance_of(Apis::OsPlaces::Client).to receive(:call).with("SE220HW").and_call_original

      described_class.new.get("SE220HW")
    end
  end
end
