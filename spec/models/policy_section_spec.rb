# frozen_string_literal: true

require "rails_helper"

RSpec.describe PolicySection, type: :model do
  subject(:policy_section) { build(:policy_section) }

  describe "validations" do
    describe "#section" do
      it "validates presence" do
        policy_section.section = nil
        expect { policy_section.valid? }.to change { policy_section.errors[:section] }.to ["Enter a section for the policy section"]
      end

      it "validates uniqueness within scope of policy_class_id" do
        create(:policy_section, section: policy_section.section, policy_class: policy_section.policy_class)
        expect { policy_section.valid? }.to change { policy_section.errors[:section] }.to ["has already been taken"]
      end
    end

    describe "#description" do
      it "validates presence" do
        policy_section.description = nil
        expect { policy_section.valid? }.to change { policy_section.errors[:description] }.to ["Enter a description for the policy section"]
      end
    end

    describe "#policy_class" do
      it "validates presence" do
        policy_section.policy_class = nil
        expect { policy_section.valid? }.to change { policy_section.errors[:policy_class] }.to ["must exist"]
      end
    end

    describe "#title" do
      subject(:policy_section) { described_class.new(title: "invalid") }

      it "validates inclusion" do
        expect { policy_section.valid? }.to change { policy_section.errors[:title] }.to ["Select a valid title"]
      end
    end
  end
end
