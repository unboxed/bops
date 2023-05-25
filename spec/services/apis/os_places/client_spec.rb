# frozen_string_literal: true

require "rails_helper"

RSpec.describe Apis::OsPlaces::Client do
  let(:client) { described_class.new }

  describe "#call" do
    it "is successful" do
      expect(client.call("SE220HW").status).to eq(200)
    end
  end
end
