# frozen_string_literal: true

require "rails_helper"

RSpec.describe PolicyClass, type: :model do
  let(:policy_class) { build(:policy_class) }

  describe "validation" do
    it "has a  valid factory" do
      expect(build(:policy_class)).to be_valid
    end
  end

  describe "stamp_part!" do
    it "adds the part into the class" do
      expect { policy_class.stamp_part!(3) }.to change(policy_class, :part).from(nil).to(3)
    end
  end

  describe "stamp_status!" do
    it "adds the status to all children policies" do
      policy_class.policies.each { |p| expect(p.keys).not_to include "status" }

      policy_class.stamp_status!

      policy_class.policies.each { |p| expect(p["status"]).to eq "to_be_determined" }
    end
  end
end
