# frozen_string_literal: true

require "rails_helper"

RSpec.describe Apis::PlanningData::Client do
  let(:client) { described_class.new }

  describe "#get" do
    it "is successful" do
      expect(client.get("reference=LBH&dataset=local-authority").status).to eq(200)
    end
  end

  describe "#get_entity" do
    it "is successful" do
      expect(client.get_entity("1000005").status).to eq(200)
    end
  end
end
