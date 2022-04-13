# frozen_string_literal: true

require "rails_helper"

RSpec.describe Apis::Mapit::Client do
  let(:client) { described_class.new }

  describe "#call" do
    let(:faraday_connection) { spy }
    let(:url) { "https://mapit.mysociety.org" }

    it "makes a Faraday connection" do
      allow(Faraday).to receive(:new).with(url: url).and_yield(faraday_connection)

      client.call("SE220HW")
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
