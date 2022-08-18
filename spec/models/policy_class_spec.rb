# frozen_string_literal: true

require "rails_helper"

RSpec.describe PolicyClass, type: :model do
  let(:policy_class) { build(:policy_class) }

  describe "#complies?" do
    let(:policy_class) do
      build(:policy_class, policies: [policy1, policy2, policy3])
    end

    let(:policy1) { build(:policy_reference, status: "compliant") }
    let(:policy2) { build(:policy_reference, status: "compliant") }
    let(:policy3) { build(:policy_reference, status: "compliant") }

    context "when all policies are compliant" do
      it "returns true" do
        expect(policy_class.complies?).to eq(true)
      end
    end

    context "when a policy does not comply" do
      let(:policy3) { build(:policy_reference, status: "does_not_comply") }

      it "returns false" do
        expect(policy_class.complies?).to eq(false)
      end
    end

    context "when a policy is do be determined" do
      let(:policy3) { build(:policy_reference, status: "to_be_determined") }

      it "returns false" do
        expect(policy_class.complies?).to eq(false)
      end
    end
  end

  describe "#does_not_comply?" do
    let(:policy_class) do
      build(:policy_class, policies: [policy1, policy2, policy3])
    end

    let(:policy1) { build(:policy_reference, status: "compliant") }
    let(:policy2) { build(:policy_reference, status: "compliant") }
    let(:policy3) { build(:policy_reference, status: "compliant") }

    context "when all policies are compliant" do
      it "returns false" do
        expect(policy_class.does_not_comply?).to eq(false)
      end
    end

    context "when a policy does not comply" do
      let(:policy3) { build(:policy_reference, status: "does_not_comply") }

      it "returns true" do
        expect(policy_class.does_not_comply?).to eq(true)
      end
    end

    context "when a policy is do be determined" do
      let(:policy2) { build(:policy_reference, status: "does_not_comply") }
      let(:policy3) { build(:policy_reference, status: "to_be_determined") }

      it "returns false" do
        expect(policy_class.does_not_comply?).to eq(false)
      end
    end
  end

  describe "#in_assessment?" do
    let(:policy_class) do
      build(:policy_class, policies: [policy1, policy2, policy3])
    end

    let(:policy1) { build(:policy_reference, status: "compliant") }
    let(:policy2) { build(:policy_reference, status: "compliant") }
    let(:policy3) { build(:policy_reference, status: "compliant") }

    context "when all policies are compliant" do
      it "returns false" do
        expect(policy_class.in_assessment?).to eq(false)
      end
    end

    context "when a policy does not comply" do
      let(:policy3) { build(:policy_reference, status: "does_not_comply") }

      it "returns false" do
        expect(policy_class.in_assessment?).to eq(false)
      end
    end

    context "when a policy is do be determined" do
      let(:policy2) { build(:policy_reference, status: "does_not_comply") }
      let(:policy3) { build(:policy_reference, status: "to_be_determined") }

      it "returns false" do
        expect(policy_class.in_assessment?).to eq(true)
      end
    end
  end

  describe "#non_compliant_policies" do
    let(:policy_class) do
      build(:policy_class, policies: [policy1, policy2, policy3])
    end

    let(:policy1) { build(:policy_reference, status: "compliant") }
    let(:policy2) { build(:policy_reference, status: "does_not_comply") }
    let(:policy3) { build(:policy_reference, status: "to_be_determined") }

    it "returns non compliant policies" do
      expect(policy_class.non_compliant_policies).to contain_exactly(policy2)
    end
  end

  describe "validation" do
    it "has a valid factory" do
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

  describe "to_param" do
    it "joins the class's part and id" do
      expect(build(:policy_class, part: "1", id: "A").to_param).to eq "1-A"
    end
  end
end
