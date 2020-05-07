# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlanningApplication, type: :model do
  subject { create :planning_application }

  describe "statuses" do
    it "has a list of statuses" do
      expect(described_class.statuses).to eq(
        "in_assessment" => 0, "awaiting_determination" => 1, "determined" => 2
      )
    end
  end

  describe "decisions" do
    let(:assessor)          { create :user, :assessor }
    let(:reviewer)          { create :user, :reviewer }

    let(:assessor_decision) { create(:decision, user: assessor) }
    let(:reviewer_decision) { create(:decision, user: reviewer) }

    before do
      subject.decisions << assessor_decision << reviewer_decision
    end

    describe "assessor_decision" do
      it "returns the assessor's decision" do
        expect(subject.assessor_decision).to eq assessor_decision
      end
    end

    describe "reviewer_decision" do
      it "returns the reviewer's decision" do
        expect(subject.reviewer_decision).to eq reviewer_decision
      end
    end
  end
end
