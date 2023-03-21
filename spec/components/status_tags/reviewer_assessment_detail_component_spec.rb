# frozen_string_literal: true

require "rails_helper"

RSpec.describe StatusTags::ReviewerAssessmentDetailComponent, type: :component do
  let(:planning_application) { create(:planning_application) }

  let(:component) do
    described_class.new(
      planning_application:,
      assessment_detail:
    )
  end

  context "when assessor has not started assessment detail" do
    let(:assessment_detail) do
      planning_application.assessment_details.new(category: :summary_of_work)
    end

    it "renders 'Not started' status" do
      render_inline(component)

      expect(page).to have_content("Not started")
    end
  end

  context "when assessor has started but no completed assessment detail" do
    let(:assessment_detail) do
      create(
        :assessment_detail,
        :summary_of_work,
        planning_application:,
        assessment_status: :in_progress
      )
    end

    it "renders 'In progress' status" do
      render_inline(component)

      expect(page).to have_content("In progress")
    end
  end

  context "when assessor has completed assessment detail" do
    let(:assessment_detail) do
      create(
        :assessment_detail,
        :summary_of_work,
        planning_application:,
        assessment_status: :complete
      )
    end

    it "renders 'Complete' status" do
      render_inline(component)

      expect(page).to have_content("Completed")
    end
  end

  context "when reviewer has requested update to assessment detail" do
    let(:assessment_detail) do
      create(
        :assessment_detail,
        :summary_of_work,
        planning_application:,
        assessment_status: :complete,
        review_status: :complete,
        reviewer_verdict: :rejected
      )
    end

    let(:component) do
      described_class.new(
        planning_application:,
        assessment_detail:
      )
    end

    before do
      create(
        :recommendation,
        planning_application:,
        challenged: true,
        status: :review_complete,
        reviewer_comment: "rejected"
      )
    end

    it "renders 'To be reviewed' status" do
      render_inline(component)

      expect(page).to have_content("To be reviewed")
    end
  end

  context "when assessor has updated assessment detail" do
    let(:assessment_detail) do
      create(
        :assessment_detail,
        :summary_of_work,
        planning_application:,
        assessment_status: :complete
      )
    end

    let(:component) do
      described_class.new(
        planning_application:,
        assessment_detail:
      )
    end

    before do
      create(
        :recommendation,
        planning_application:,
        submitted: true
      )

      create(
        :assessment_detail,
        :summary_of_work,
        planning_application:,
        review_status: :complete,
        reviewer_verdict: :rejected,
        created_at: 2.days.ago
      )
    end

    it "renders 'Updated' status" do
      render_inline(component)

      expect(page).to have_content("Updated")
    end

    context "when reviewer has re-reviewed assessment detail" do
      let(:assessment_detail) do
        create(
          :assessment_detail,
          :summary_of_work,
          planning_application:,
          assessment_status: :complete,
          review_status: :complete,
          reviewer_verdict: :accepted
        )
      end

      it "renders 'Complete' status" do
        render_inline(component)

        expect(page).to have_content("Completed")
      end
    end
  end
end
