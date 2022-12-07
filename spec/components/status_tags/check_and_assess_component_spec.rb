# frozen_string_literal: true

require "rails_helper"

RSpec.describe StatusTags::CheckAndAssessComponent, type: :component do
  include ActionView::TestCase::Behavior

  let(:planning_application) { create(:planning_application, :in_assessment) }

  let(:planning_applicaton_presenter) do
    PlanningApplicationPresenter.new(view, planning_application)
  end

  context "when recommendation has been submitted" do
    before do
      create(
        :recommendation,
        submitted: true,
        planning_application: planning_application
      )

      render_inline(
        described_class.new(planning_application: planning_applicaton_presenter)
      )
    end

    it "renders 'Complete' status" do
      expect(page).to have_content("Complete")
    end
  end

  context "when recommendation has been rejected" do
    before do
      create(
        :recommendation,
        submitted: true,
        challenged: true,
        status: :review_complete,
        planning_application: planning_application,
        reviewer_comment: "comment"
      )

      render_inline(
        described_class.new(planning_application: planning_applicaton_presenter)
      )
    end

    it "renders 'To be reviewed' status" do
      expect(page).to have_content("To be reviewed")
    end
  end

  context "when assessment is in progress" do
    before do
      create(:recommendation, planning_application: planning_application)

      render_inline(
        described_class.new(planning_application: planning_applicaton_presenter)
      )
    end

    it "renders 'In progress' status" do
      expect(page).to have_content("In progress")
    end
  end

  context "when assessment has not been started" do
    before do
      render_inline(
        described_class.new(planning_application: planning_applicaton_presenter)
      )
    end

    it "renders 'Not started' status" do
      expect(page).to have_content("Not started")
    end
  end
end
