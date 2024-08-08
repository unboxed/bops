# frozen_string_literal: true

require "rails_helper"

RSpec.describe PolicySchedule, type: :model do
  subject(:policy_schedule) { build(:policy_schedule) }

  describe "validations" do
    describe "#number" do
      it "validates presence" do
        policy_schedule.number = nil
        expect { policy_schedule.valid? }.to change { policy_schedule.errors[:number] }.to ["can't be blank"]
      end

      it "validates uniqueness" do
        create(:policy_schedule, number: policy_schedule.number)
        expect { policy_schedule.valid? }.to change { policy_schedule.errors[:number] }.to ["has already been taken"]
      end
    end
  end
end
