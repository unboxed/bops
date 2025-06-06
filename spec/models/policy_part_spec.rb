# frozen_string_literal: true

require "rails_helper"

RSpec.describe PolicyPart, type: :model do
  subject(:policy_part) { build(:policy_part) }

  describe "validations" do
    describe "#number" do
      it "validates presence" do
        policy_part.number = nil
        expect { policy_part.valid? }.to change { policy_part.errors[:number] }.to ["Enter a number for the part", "The part number must be a number"]
      end

      it "validates numericality" do
        policy_part.number = "NaN"
        expect { policy_part.valid? }.to change { policy_part.errors[:number] }.to ["The part number must be a number"]
      end

      it "validates uniqueness within scope of policy_schedule_id" do
        create(:policy_part, number: policy_part.number, policy_schedule: policy_part.policy_schedule)
        expect { policy_part.valid? }.to change { policy_part.errors[:number] }.to ["has already been taken"]
      end
    end

    describe "#name" do
      it "validates presence" do
        policy_part.name = nil
        expect { policy_part.valid? }.to change { policy_part.errors[:name] }.to ["Enter a description for the part"]
      end
    end
  end
end
