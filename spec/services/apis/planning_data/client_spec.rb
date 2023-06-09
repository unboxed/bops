# frozen_string_literal: true

require "rails_helper"

RSpec.describe Apis::PlanningData::Client do
  let(:client) { described_class.new }

  describe "#call" do
    it "is successful" do
      expect(client.call("reference=LBH&dataset=local-authority").status).to eq(200)
    end
  end
end
