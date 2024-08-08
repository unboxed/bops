# frozen_string_literal: true

require "rails_helper"

RSpec.describe NewPolicyClass, type: :model do
  subject(:policy_class) { build(:new_policy_class) }

  describe "validations" do
    describe "#section" do
      it "validates presence" do
        policy_class.section = nil
        expect { policy_class.valid? }.to change { policy_class.errors[:section] }.to ["can't be blank"]
      end

      it "validates uniqueness within scope of policy_part_id" do
        create(:new_policy_class, section: policy_class.section, policy_part: policy_class.policy_part)
        expect { policy_class.valid? }.to change { policy_class.errors[:section] }.to ["has already been taken"]
      end
    end

    describe "#name" do
      it "validates presence" do
        policy_class.name = nil
        expect { policy_class.valid? }.to change { policy_class.errors[:name] }.to ["can't be blank"]
      end
    end

    describe "#policy_part" do
      it "validates presence" do
        policy_class.policy_part = nil
        expect { policy_class.valid? }.to change { policy_class.errors[:policy_part] }.to ["must exist"]
      end
    end
  end
end
