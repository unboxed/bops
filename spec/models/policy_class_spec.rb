# frozen_string_literal: true

require "rails_helper"

RSpec.describe PolicyClass do
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
        section: "",
        description: "The enlargement, improvement or other alteration\nof a dwellinghouse.\n",
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
          expect(policy_class.valid?).to be(true)
        end
      end

      context "when status is in_assessment" do
        let(:policy_class) do
          build(:policy_class, :in_assessment, policies: [policy])
        end

        it "returns true" do
          expect(policy_class.valid?).to be(true)
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
          expect(policy_class.valid?).to be(false)
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
          expect(policy_class.valid?).to be(true)
        end
      end
    end
  end

  describe "#next" do
    let(:planning_application) { create(:planning_application) }

    let(:policy_class) do
      create(
        :policy_class,
        section: "1b",
        planning_application: planning_application
      )
    end

    before do
      %w[1a 2a 2b].each do |section|
        create(
          :policy_class,
          section: section,
          planning_application: planning_application
        )
      end
    end

    it "returns next policy class for the application ordered by section" do
      expect(policy_class.next.section).to eq("2a")
    end
  end

  describe "#previous" do
    let(:planning_application) { create(:planning_application) }

    let(:policy_class) do
      create(
        :policy_class,
        section: "2a",
        planning_application: planning_application
      )
    end

    before do
      %w[1a 1b 2b].each do |section|
        create(
          :policy_class,
          section: section,
          planning_application: planning_application
        )
      end
    end

    it "returns previous policy class for the application ordered by section" do
      expect(policy_class.previous.section).to eq("1b")
    end
  end

  describe "#update_required?" do
    context "when review_policy_class status is 'complete' and status is 'to_be_reviewed'" do
      let(:policy_class) { create(:policy_class, status: :to_be_reviewed) }

      before do
        create(
          :review_policy_class,
          policy_class: policy_class,
          status: :complete
        )
      end

      it "returns true" do
        expect(policy_class.update_required?).to be(true)
      end
    end

    context "when review_policy_class status is not 'complete' and status is 'to_be_reviewed'" do
      let(:policy_class) { create(:policy_class, status: :to_be_reviewed) }

      before do
        create(
          :review_policy_class,
          policy_class: policy_class,
          status: :not_started
        )
      end

      it "returns false" do
        expect(policy_class.update_required?).to be(false)
      end
    end

    context "when review_policy_class status is 'complete' but status is not 'to_be_reviewed'" do
      let(:policy_class) { create(:policy_class, status: :complete) }

      before do
        create(
          :review_policy_class,
          policy_class: policy_class,
          status: :complete
        )
      end

      it "returns false" do
        expect(policy_class.update_required?).to be(false)
      end
    end
  end
end
