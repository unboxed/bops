# frozen_string_literal: true

require "rails_helper"

RSpec.describe Apis::Paapi::Client do
  let(:client) { described_class.new }

  describe "#call" do
    it "is successful" do
      expect(client.call("100081043511").status).to eq(200)
    end
  end
end
