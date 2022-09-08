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

  describe "#valid?" do
    it "has a valid factory" do
      expect(build(:policy_class)).to be_valid
    end

    context "when all policies are determined" do
      let(:policy) { build(:policy, :complies) }

      context "when status is complete" do
        let(:policy_class) do
          build(:policy_class, :complete, policies: [policy])
        end

        it "returns true" do
          expect(policy_class.valid?).to eq(true)
        end
      end

      context "when status is in_assessment" do
        let(:policy_class) do
          build(:policy_class, :in_assessment, policies: [policy])
        end

        it "returns true" do
          expect(policy_class.valid?).to eq(true)
        end
      end
    end

    context "when some policies are to be determined" do
      let(:policy) { build(:policy, :to_be_determined) }

      context "when status is complete" do
        let(:policy_class) do
          build(:policy_class, :complete, policies: [policy])
        end

        it "returns false" do
          expect(policy_class.valid?).to eq(false)
        end

        it "sets error message" do
          policy_class.valid?
          expect(policy_class.errors.messages[:status]).to contain_exactly(
            "All policies must be assessed"
          )
        end
      end

      context "when status is in_assessment" do
        let(:policy_class) do
          build(:policy_class, :in_assessment, policies: [policy])
        end

        it "returns true" do
          expect(policy_class.valid?).to eq(true)
        end
      end
    end
  end
end
