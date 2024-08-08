# frozen_string_literal: true

require "rails_helper"

RSpec.describe PolicySection, type: :model do
  subject(:policy_section) { build(:policy_section) }

  describe "validations" do
    describe "#section" do
      it "validates presence" do
        policy_section.section = nil
        expect { policy_section.valid? }.to change { policy_section.errors[:section] }.to ["can't be blank"]
      end

      it "validates uniqueness within scope of new_policy_class_id" do
        create(:policy_section, section: policy_section.section, new_policy_class: policy_section.new_policy_class)
        expect { policy_section.valid? }.to change { policy_section.errors[:section] }.to ["has already been taken"]
      end
    end

    describe "#description" do
      it "validates presence" do
        policy_section.description = nil
        expect { policy_section.valid? }.to change { policy_section.errors[:description] }.to ["can't be blank"]
      end
    end

    describe "#new_policy_class" do
      it "validates presence" do
        policy_section.new_policy_class = nil
        expect { policy_section.valid? }.to change { policy_section.errors[:new_policy_class] }.to ["must exist"]
      end
    end
  end
end
