# frozen_string_literal: true

require "rails_helper"

RSpec.describe DocumentHelper, type: :helper do
  describe "#override_numbers" do
    let!(:document) { FactoryBot.build :document }

    it "returns an empty string when numbers are empty" do
      expect(override_numbers(document)).to eq("")
    end

    it "returns the correct numbers when the field is populated" do
      document.update!(numbers: "450")
      document.reload

      expect(override_numbers(document)).to eq("450")
    end
  end
end
