# frozen_string_literal: true

require "rails_helper"

RSpec.describe PolicyClass, type: :model do
  let(:klass) { build(:policy_class) }

  describe "validation" do
    it "has a  valid factory" do
      expect(build(:policy_class)).to be_valid
    end
  end

  describe "stamp_part!" do
    it "adds the part into the class" do
      expect { klass.stamp_part!(3) }.to change(klass, :part).from(nil).to(3)
    end
  end

  describe "stamp_status!" do
    it "adds the status to all children policies" do
      klass.policies.each { |p| expect(p.keys).not_to include "status" }

      klass.stamp_status!

      klass.policies.each { |p| expect(p["status"]).to eq "to_be_determined" }
    end
  end
end
