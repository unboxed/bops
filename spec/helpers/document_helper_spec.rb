# frozen_string_literal: true

require "rails_helper"

RSpec.describe DocumentHelper, type: :helper do
  describe "#archive_reason_collection_for_radio_buttons" do
    it "maps the reasons correctly" do
      expect(archive_reason_collection_for_radio_buttons[2])
          .to eq(["dimensions", "Revise dimensions"])
    end
  end

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
