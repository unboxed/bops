# frozen_string_literal: true

require "rails_helper"

RSpec.describe PolicySchedule, type: :model do
  subject(:policy_schedule) { build(:policy_schedule) }

  describe "validations" do
    describe "#number" do
      it "validates presence" do
        policy_schedule.number = nil
        expect { policy_schedule.valid? }.to change { policy_schedule.errors[:number] }.to ["Enter a number for the schedule", "The schedule number must be a number"]
      end

      it "validates numericality" do
        policy_schedule.number = "NaN"
        expect { policy_schedule.valid? }.to change { policy_schedule.errors[:number] }.to ["The schedule number must be a number"]
      end

      it "validates uniqueness" do
        create(:policy_schedule, number: policy_schedule.number)
        expect { policy_schedule.valid? }.to change { policy_schedule.errors[:number] }.to ["has already been taken"]
      end
    end
  end
end
