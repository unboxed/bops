# frozen_string_literal: true

require "rails_helper"

RSpec.describe StatusTags::AssessmentDetailsReviewComponent, type: :component do
  let(:planning_application) { create(:planning_application) }
  let(:review_status) { nil }
  let(:assessment_status) { :complete }
  let(:reviewer_verdict) { :accepted }

  before do
    create(
      :assessment_detail,
      :summary_of_work,
      planning_application:,
      reviewer_verdict:,
      review_status:,
      assessment_status:,
      created_at: 1.day.ago
    )

    create(
      :recommendation,
      submitted: true,
      planning_application:
    )
  end

  context "when an assessment detail has been updated" do
    let(:reviewer_verdict) { nil }

    before do
      create(
        :assessment_detail,
        :summary_of_work,
        review_status: :complete,
        reviewer_verdict: :rejected,
        planning_application:,
        created_at: 2.days.ago
      )

      render_inline(
        described_class.new(planning_application:)
      )
    end

    it "renders 'Updated' status" do
      expect(page).to have_content("Updated")
    end
  end

  context "when the review is complete" do
    let(:review_status) { :complete }

    before do
      render_inline(
        described_class.new(planning_application:)
      )
    end

    it "renders 'Checked' status" do
      expect(page).to have_content("Checked")
    end
  end

  context "when the review is in progress" do
    let(:review_status) { :in_progress }

    before do
      render_inline(
        described_class.new(planning_application:)
      )
    end

    it "renders 'In progress' status" do
      expect(page).to have_content("In progress")
    end
  end

  context "when the review has not been started" do
    let(:reviewer_verdict) { nil }

    before do
      render_inline(
        described_class.new(planning_application:)
      )
    end

    it "renders 'Not started' status" do
      expect(page).to have_content("Not started")
    end
  end
end
