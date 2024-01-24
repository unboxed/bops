# frozen_string_literal: true

require "rails_helper"

RSpec.shared_examples "PhoneNumberValidator" do
  describe "#valid?" do
    %w[qwerty 123 1234567890123456].each do |value|
      context "when value is #{value}" do
        before { record.send(:"#{attribute}=", value) }

        it "returns false" do
          expect(record.valid?).to be(false)
        end

        it "sets error message" do
          record.valid?

          expect(
            record.errors.messages[attribute]
          ).to contain_exactly(
            "is invalid"
          )
        end
      end
    end

    ["07717-123-123", "07717123123", "+447717123123", "07717 123 123", "(07717)123123"].each do |value|
      context "when value is #{value}" do
        it "returns true" do
          record.send(:"#{attribute}=", value)
          expect(record.valid?).to be(true)
        end
      end
    end
  end
end
