# frozen_string_literal: true

require "rails_helper"

RSpec.describe StatusTags::AssessRecommendationComponent, type: :component do
  let(:planning_application) do
    create(:planning_application, :in_assessment)
  end

  context "when there is no recommendation" do
    before do
      render_inline(
        described_class.new(planning_application: planning_application)
      )
    end

    it "renders 'Not started' status" do
      expect(page).to have_content("Not started")
    end
  end

  context "when there is a recommendation" do
    before do
      create(
        :recommendation,
        planning_application: planning_application,
        status: status,
        challenged: challenged,
        reviewer_comment: "comment"
      )

      render_inline(
        described_class.new(planning_application: planning_application)
      )
    end

    context "when the recommendation is rejected" do
      let(:status) { :review_complete }
      let(:challenged) { true }

      it "renders 'To be reviewed' status" do
        expect(page).to have_content("To be reviewed")
      end
    end

    context "when the recommendation is in progress" do
      let(:status) { :assessment_in_progress }
      let(:challenged) { false }

      it "renders 'In progress' status" do
        expect(page).to have_content("In progress")
      end
    end

    context "when the recommendation is complete" do
      let(:status) { :assessment_complete }
      let(:challenged) { false }

      it "renders 'Complete' status" do
        expect(page).to have_content("Complete")
      end
    end
  end
end
