# frozen_string_literal: true

require "rails_helper"

RSpec.describe Constraint do
  describe "validations" do
    subject(:constraint) { described_class.new }

    describe "#type" do
      it "validates presence" do
        expect { constraint.valid? }.to change { constraint.errors[:type] }.to ["can't be blank"]
      end

      it "validates uniqueness" do
        create(:constraint, type: "designated.conservationArea")

        expect { described_class.create!(type: "designated.conservationArea") }.to raise_error(
          ActiveRecord::RecordInvalid, "Validation failed: Category can't be blank, Type has already been taken"
        )
      end
    end

    describe "#category" do
      it "validates presence" do
        expect { constraint.valid? }.to change { constraint.errors[:category] }.to ["can't be blank"]
      end
    end
  end

  describe "scopes" do
    describe ".options_for_local_authority" do
      let!(:local_authority1) { create(:local_authority) }
      let!(:local_authority2) { create(:local_authority, :southwark) }

      let!(:constraint1) { create(:constraint, local_authority: local_authority1) }
      let!(:constraint2) { create(:constraint, local_authority: nil) }
      let!(:constraint3) { create(:constraint, local_authority: local_authority2) }

      it "returns available constraint options for a local authority" do
        expect(described_class.options_for_local_authority(local_authority1)).to match_array([constraint1, constraint2])
        expect(described_class.options_for_local_authority(local_authority2)).to match_array([constraint2, constraint3])
      end
    end
  end

  describe "class methods" do
    describe "#grouped_by_category" do
      let!(:local_authority1) { create(:local_authority) }
      let!(:local_authority2) { create(:local_authority, :southwark) }

      let!(:constraint1) { create(:constraint, category: "trees", local_authority: local_authority1) }
      let!(:constraint2) { create(:constraint, category: "ecology", local_authority: nil) }
      let!(:constraint3) { create(:constraint, category: "heritage_and_conservation", local_authority: local_authority2) }

      it "returns all constraint options for a local authority grouped by category" do
        expect(described_class.grouped_by_category(local_authority1)).to eq(
          {
            "trees" => [constraint1], "ecology" => [constraint2]
          }
        )

        expect(described_class.grouped_by_category(local_authority2)).to eq(
          {
            "ecology" => [constraint2], "heritage_and_conservation" => [constraint3]
          }
        )
      end
    end
  end
end
