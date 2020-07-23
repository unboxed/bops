# frozen_string_literal: true

#
require 'rails_helper'

RSpec.describe PlanningApplicationHelper, type: :helper do
  describe "#days_color" do
    it "returns the correct colour for less than 6" do
      expect(days_color(3)).to eq("red")
    end

    it "returns the correct colour for 6..10" do
      expect(days_color(7)).to eq("yellow")
    end

    it "returns the correct colour for 11 and over" do
      expect(days_color(14)).to eq("green")
    end
  end

  describe "#mark_completed?" do
    subject { create :planning_application }

    let(:assessor)          { create :user, :assessor }
    let(:reviewer)          { create :user, :reviewer }

    let(:assessor_decision) { create(:decision, :granted, user: assessor) }
    let(:reviewer_decision) { create(:decision, :refused, user: reviewer) }

    before do
      subject.decisions << assessor_decision << reviewer_decision
      subject.reload.reviewer_decision.update(correction: "I do not agree")
    end

    it "returns true for Assess the proposal" do
      step_name = "Assess the proposal"

      expect(mark_completed?(step_name, subject)).to eq(true)
    end

    it "returns true for Submit the recommendation" do
      step_name = "Submit the recommendation"

      expect(mark_completed?(step_name, subject)).to eq(true)
    end

    it "returns true for Reassess the proposal" do
      step_name = "Reassess the proposal"

      expect(mark_completed?(step_name, subject)).to eq(true)
    end

    it "returns true for Resubmit the recommendation" do
      step_name = "Resubmit the recommendation"

      expect(mark_completed?(step_name, subject)).to eq(true)
    end

    it "returns true for Review the recommendation" do
      step_name = "Review the recommendation"

      expect(mark_completed?(step_name, subject)).to eq(true)
    end

    it "returns true for Review the corrections" do
      step_name = "Review the corrections"

      expect(mark_completed?(step_name, subject)).to eq(true)
    end
  end
  end
