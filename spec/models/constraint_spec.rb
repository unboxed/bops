# frozen_string_literal: true

require "rails_helper"

RSpec.describe Constraint do
  describe "validations" do
    subject(:constraint) { described_class.new }

    describe "#name" do
      it "validates presence" do
        expect { constraint.valid? }.to change { constraint.errors[:name] }.to ["can't be blank"]
      end

      it "validates uniqueness" do
        create(:constraint, name: "Flood zone")

        expect { described_class.create!(name: "Flood zone") }.to raise_error(
          ActiveRecord::RecordInvalid, "Validation failed: Category can't be blank, Name has already been taken"
        )
      end
    end

    describe "#category" do
      it "validates presence" do
        expect { constraint.valid? }.to change { constraint.errors[:category] }.to ["can't be blank"]
      end

      it "validates enum type" do
        expect { described_class.new(category: "random") }.to raise_error(ArgumentError, "'random' is not a valid category")
      end
    end
  end
end
