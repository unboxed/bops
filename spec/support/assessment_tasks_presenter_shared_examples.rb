# frozen_string_literal: true

require "rails_helper"

RSpec.shared_examples "AssessmentTasksPresenter" do
  describe "#assessment_tasklist_in_progress?" do
    let(:planning_application) { create(:planning_application) }
    let(:presenter) { described_class.new(view, planning_application) }

    context "when no assessment tasks objects are present" do
      it "returns false" do
        expect(presenter.assessment_tasklist_in_progress?).to be(false)
      end
    end

    context "when recommendation is present" do
      before do
        create(:recommendation, planning_application:)
      end

      it "returns true" do
        expect(presenter.assessment_tasklist_in_progress?).to be(true)
      end
    end

    context "when policy class is present" do
      before do
        create(:policy_class, planning_application:)
      end

      it "returns true" do
        expect(presenter.assessment_tasklist_in_progress?).to be(true)
      end
    end

    context "when consistency checklist is present" do
      before do
        create(
          :consistency_checklist,
          planning_application:
        )
      end

      it "returns true" do
        expect(presenter.assessment_tasklist_in_progress?).to be(true)
      end
    end

    context "when assessment detail is present" do
      before do
        create(
          :assessment_detail,
          planning_application:
        )
      end

      it "returns true" do
        expect(presenter.assessment_tasklist_in_progress?).to be(true)
      end
    end

    context "when permitted development right is present" do
      before do
        create(
          :permitted_development_right,
          planning_application:
        )
      end

      it "returns true" do
        expect(presenter.assessment_tasklist_in_progress?).to be(true)
      end
    end

    context "when conditions are present" do
      before do
        condition_set = create(
          :condition_set,
          planning_application:
        )

        create(:condition, condition_set:)
      end

      it "returns true" do
        expect(presenter.assessment_tasklist_in_progress?).to be(true)
      end
    end
  end
end
