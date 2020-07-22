# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlanningApplication, type: :model do
  subject { create :planning_application }

  describe "decision validations" do
    let(:assessor)          { build :user, :assessor }
    let(:reviewer)          { build :user, :reviewer }

    let(:decision_associated_with_reviewer) { build :decision, :granted, user: reviewer }
    let(:decision_associated_with_assessor) { build :decision, :granted, user: assessor }

    it "is invalid when an assessor_decision is associated with a non-assessor" do
      subject.assessor_decision = decision_associated_with_reviewer

      expect(subject).to be_invalid
      expect(subject.errors.full_messages).to include "Assessor decision cannot be associated with a non-assessor"
    end

    it "is valid when an assessor_decision is associated with an assessor" do
      subject.assessor_decision = decision_associated_with_assessor

      expect(subject).to be_valid
    end

    it "is invalid when a reviewer_decision is associated with a non-reviewer" do
      subject.reviewer_decision = decision_associated_with_assessor

      expect(subject).to be_invalid
      expect(subject.errors.full_messages).to include "Reviewer decision cannot be associated with a non-reviewer"
    end

    it "is valid when an reviewer_decision is associated with an reviewer" do
      subject.reviewer_decision = decision_associated_with_reviewer

      expect(subject).to be_valid
    end
  end

  describe "statuses" do
    it "has a list of statuses" do
      expect(described_class.statuses).to eq(
        "in_assessment" => 0, "awaiting_determination" => 1, "determined" => 2
      )
    end
  end

  describe "update_and_timestamp_status" do
    described_class.statuses.keys.each do |status|
      context "for the #{status} status" do
        before do
          # Set timestamp to differentiate from now
          subject.update("#{status}_at": 1.hour.ago)

          subject.update_and_timestamp_status(status)
        end

        it "sets the status to #{status}" do
          expect(subject.status).to eq status
        end

        it "sets the timestamp for #{status}_at to now" do
          expect(subject.send("#{status}_at")).to be_within(1.second).of(Time.current)
        end
      end
    end
  end

  describe "decisions" do
    let(:assessor)          { create :user, :assessor }
    let(:reviewer)          { create :user, :reviewer }

    let(:assessor_decision) { create(:decision, :granted, user: assessor) }
    let(:reviewer_decision) { create(:decision, :granted, user: reviewer) }

    before do
      subject.decisions << assessor_decision << reviewer_decision
    end

    describe "assessor_decision" do
      it "returns the assessor's decision" do
        expect(subject.reload.assessor_decision).to eq assessor_decision
      end
    end

    describe "reviewer_decision" do
      it "returns the reviewer's decision" do
        expect(subject.reload.reviewer_decision).to eq reviewer_decision
      end
    end
  end

  subject { create :planning_application, id: 1000 }

  describe "#reference" do
    it "pads the ID correctly" do
      expect(subject.reference).to eq "00001000"
    end
  end

  describe "corrections" do
    let(:assessor)          { create :user, :assessor }
    let(:reviewer)          { create :user, :reviewer }

    let(:assessor_decision) { create(:decision, :granted, user: assessor) }
    let(:reviewer_decision) { create(:decision, :granted, user: reviewer) }

    before do
      subject.decisions << assessor_decision << reviewer_decision
      subject.update_and_timestamp_status("awaiting_determination")
    end

    it "expects the correction to be valid" do
      subject.reload.reviewer_decision.update(correction: "I don't agree")

      expect(subject.reload.reviewer_decision).to be_valid
    end

    describe "#correction_requested?" do
      it "sets the correct state when reviewer adds correction" do
        subject.reload.reviewer_decision.update(correction: "I don't agree")
        expect(subject.correction_requested?).to be true
      end
    end

    describe "#correction_provided?" do
      it "sets the correct state when assessor responds" do
        subject.reload.reviewer_decision.update(correction: "I don't agree")
        subject.reload.assessor_decision.update!(comment_met: "returned for review")
        expect(subject.correction_provided?).to be true
      end
    end

    describe "#correction?" do
      it "sets the correct state when assessor responds" do
        subject.reload.reviewer_decision.update(correction: "I don't agree")
        expect(subject.correction?).to be true
      end
    end
  end

  describe "#reference" do
    it "pads the ID correctly" do
      expect(subject.reference).to eq "00001000"
    end
  end
end
