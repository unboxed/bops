# frozen_string_literal: true

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

  describe "#assessor_decision_path" do
    subject { create :planning_application }

    context "without decision" do
      it "returns to new decision" do
        expect(assessor_decision_path(subject)).to eq(new_planning_application_decision_path(subject))
      end
    end

    context "with decision" do
      let(:assessor) { create :user, :assessor }
      let(:assessor_decision) { create(:decision, :granted, user: assessor) }

      before do
        subject.decisions << assessor_decision
        subject.reload
      end

      context "in assessment" do
        it "returns to edit decision" do
          expect(assessor_decision_path(subject)).to eq(edit_planning_application_decision_path(subject, subject.assessor_decision))
        end
      end

      context "awaiting determination" do
        before { subject.awaiting_determination! }
        it "returns to show decision" do
          expect(assessor_decision_path(subject)).to eq(planning_application_decision_path(subject, subject.assessor_decision))
        end
      end

      context "awaiting correction" do
        before { subject.awaiting_correction! }
        it "returns to edit decision" do
          expect(assessor_decision_path(subject)).to eq(edit_planning_application_decision_path(subject, subject.assessor_decision))
        end
      end

      context "determined" do
        before { subject.determined! }
        it "returns to show decision" do
          expect(assessor_decision_path(subject)).to eq(planning_application_decision_path(subject, subject.assessor_decision))
        end
      end
    end
  end

  describe "#reviewer_decision_path" do
    subject { create :planning_application, :awaiting_determination }

    context "without decision" do
      it "returns to new decision" do
        expect(reviewer_decision_path(subject)).to eq(new_planning_application_decision_path(subject))
      end
    end

    context "with decision" do
      let(:reviewer) { create :user, :reviewer }
      let(:reviewer_decision) { create(:decision, :refused_private_comment, user: reviewer) }

      before do
        subject.decisions << reviewer_decision
        subject.reload
      end

      context "awaiting determination" do
        it "returns to show decision" do
          expect(reviewer_decision_path(subject)).to eq(edit_planning_application_decision_path(subject, subject.reviewer_decision))
        end
      end

      context "awaiting correction" do
        before { subject.awaiting_correction! }
        it "returns to edit decision" do
          expect(reviewer_decision_path(subject)).to eq(planning_application_decision_path(subject, subject.reviewer_decision))
        end
      end

      context "determined" do
        before { subject.determined! }
        it "returns to show decision" do
          expect(reviewer_decision_path(subject)).to eq(planning_application_decision_path(subject, subject.reviewer_decision))
        end
      end
    end
  end
end
