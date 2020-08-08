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
        "in_assessment" => 0, "awaiting_determination" => 1, "awaiting_correction" => 2, "determined" => 3
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

  describe "#reference" do
    it "pads the ID correctly" do
      subject.update(id: 1000)

      expect(subject.reference).to eq "00001000"
    end
  end

  describe "#drawings_ready_for_publication?" do
    let!(:proposed_drawing_1) do
      create :drawing, :with_plan, :proposed_tags,
            planning_application: subject,
            numbers: "number"
    end

    let!(:existing_drawing) do
      create :drawing, :with_plan, :existing_tags,
            planning_application: subject
    end

    let!(:archived_drawing) do
      create :drawing, :with_plan, :proposed_tags, :archived,
            planning_application: subject,
            numbers: "number"
    end

    context "when all proposed, non-archived drawings have numbers" do
      it "returns true" do
        expect(subject.drawings_ready_for_publication?).to eq true
      end
    end

    context "when there is a proposed, non-archived drawing without numbers" do
      let!(:proposed_drawing_2) do
        create :drawing, :with_plan, :proposed_tags,
              planning_application: subject
      end

      it "returns false" do
        expect(subject.drawings_ready_for_publication?).to eq false
      end
    end

    context "when there are no drawings" do
      before do
        subject.drawings.delete_all
      end

      it "returns false" do
        expect(subject.drawings_ready_for_publication?).to eq false
      end
    end
  end
end
