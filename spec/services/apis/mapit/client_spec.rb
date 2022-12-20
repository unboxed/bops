# frozen_string_literal: true

require "rails_helper"

RSpec.describe Apis::Mapit::Client do
  let(:client) { described_class.new }

  describe "#call" do
    it "is successful" do
      expect(client.call("SE220HW").status).to eq(200)
    end

    it "removes whitespace from the postcode" do
      stub = stub_mapit_api_request_for("SE220HW")
      client.call("s e 22 0h w")
      expect(stub).to have_been_requested
    end

    it "upcases the postcode" do
      stub = stub_mapit_api_request_for("SE220HW")
      client.call("se220hw")
      expect(stub).to have_been_requested
    end
  end
end
