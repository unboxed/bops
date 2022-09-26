# frozen_string_literal: true

require "rails_helper"

RSpec.describe Apis::Paapi::Client do
  let(:client) { described_class.new }

  describe "#call" do
    let(:faraday_connection) { spy }
    let(:url) { "https://staging.paapi.services/api/v1" }

    it "makes a Faraday connection" do
      allow(Faraday).to receive(:new).with(url: url).and_yield(faraday_connection)

      client.call("100081043511")
    end
  end
end
