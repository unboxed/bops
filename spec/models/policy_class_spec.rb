# frozen_string_literal: true

require "rails_helper"

RSpec.describe PolicyClass, type: :model do
  let(:policy_class) { create(:policy_class) }

  describe "#classes_for_part" do
    let(:policy_class) { described_class.classes_for_part("1").first }

    it "builds policy classes for a part" do
      expect(policy_class).to have_attributes(
        id: nil,
        schedule: "Schedule 1",
        part: 1,
        section: "A",
        url: "https://www.legislation.gov.uk/uksi/2015/596/schedule/2/part/1/crossheading/class-a-enlargement-improvement-or-other-alteration-of-a-dwellinghouse",
        name: "enlargement, improvement or other alteration of a dwellinghouse"
      )
    end

    it "builds policies associated with each policy class" do
      expect(policy_class.policies.first).to have_attributes(
        id: nil,
        section: "1a",
        description: "Development is not permitted by Class A if\npermission to use the dwellinghouse as a\ndwellinghouse has been granted only by virtue of\nClass M, MA, N, P, PA or Q of Part 3 of this\nSchedule (changes of use);\n",
        status: "to_be_determined"
      )
    end
  end

  describe "#complies?" do
    let(:policy_class) do
      create(:policy_class, policies: [policy1, policy2, policy3])
    end

    let(:policy1) { create(:policy, :complies) }
    let(:policy2) { create(:policy, :complies) }
    let(:policy3) { create(:policy, :complies) }

    context "when all policies are complies" do
      it "returns true" do
        expect(policy_class.complies?).to eq(true)
      end
    end

    context "when a policy does not comply" do
      let(:policy3) { create(:policy, :does_not_comply) }

      it "returns false" do
        expect(policy_class.complies?).to eq(false)
      end
    end

    context "when a policy is to be determined" do
      let(:policy3) { create(:policy, :to_be_determined) }

      it "returns false" do
        expect(policy_class.complies?).to eq(false)
      end
    end
  end

  describe "#does_not_comply?" do
    let(:policy_class) do
      create(:policy_class, policies: [policy1, policy2, policy3])
    end

    let(:policy1) { create(:policy, :complies) }
    let(:policy2) { create(:policy, :complies) }
    let(:policy3) { create(:policy, :complies) }

    context "when all policies are complies" do
      it "returns false" do
        expect(policy_class.does_not_comply?).to eq(false)
      end
    end

    context "when a policy does not comply" do
      let(:policy3) { create(:policy, :does_not_comply) }

      it "returns true" do
        expect(policy_class.does_not_comply?).to eq(true)
      end
    end

    context "when a policy is do be determined" do
      let(:policy2) { create(:policy, :does_not_comply) }
      let(:policy3) { create(:policy, :to_be_determined) }

      it "returns false" do
        expect(policy_class.does_not_comply?).to eq(false)
      end
    end
  end

  describe "#in_assessment?" do
    let(:policy_class) do
      create(:policy_class, policies: [policy1, policy2, policy3])
    end

    let(:policy1) { create(:policy, :complies) }
    let(:policy2) { create(:policy, :complies) }
    let(:policy3) { create(:policy, :complies) }

    context "when all policies are complies" do
      it "returns false" do
        expect(policy_class.in_assessment?).to eq(false)
      end
    end

    context "when a policy does not comply" do
      let(:policy3) { create(:policy, :does_not_comply) }

      it "returns false" do
        expect(policy_class.in_assessment?).to eq(false)
      end
    end

    context "when a policy is do be determined" do
      let(:policy2) { create(:policy, :does_not_comply) }
      let(:policy3) { create(:policy, :to_be_determined) }

      it "returns false" do
        expect(policy_class.in_assessment?).to eq(true)
      end
    end
  end

  describe "validation" do
    it "has a valid factory" do
      expect(build(:policy_class)).to be_valid
    end
  end
end
