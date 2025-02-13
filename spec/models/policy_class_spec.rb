# frozen_string_literal: true

require "rails_helper"

RSpec.describe PolicyClass, type: :model do
  subject(:policy_class) { build(:policy_class) }

  describe "validations" do
    describe "#section" do
      it "validates presence" do
        policy_class.section = nil
        expect { policy_class.valid? }.to change { policy_class.errors[:section] }.to ["Enter a section for the class"]
      end

      it "validates uniqueness within scope of policy_part_id" do
        create(:policy_class, section: policy_class.section, policy_part: policy_class.policy_part)
        expect { policy_class.valid? }.to change { policy_class.errors[:section] }.to ["has already been taken"]
      end

      it "section is a readonly attribute" do
        policy_class.section = "AA"
        policy_class.save

        expect {
          policy_class.update(section: "B")
        }.to raise_error(ActiveRecord::ReadonlyAttributeError)

        expect(policy_class.reload.section).to eq("AA")
      end
    end

    describe "#name" do
      it "validates presence" do
        policy_class.name = nil
        expect { policy_class.valid? }.to change { policy_class.errors[:name] }.to ["Enter a description for the class"]
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
