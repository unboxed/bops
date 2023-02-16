# frozen_string_literal: true

require "rails_helper"

RSpec.describe TaskListItems::AssessmentDetailComponent, type: :component do
  let(:planning_application) { create(:planning_application) }

  context "when the assessment has not been started" do
    before do
      render_inline(
        described_class.new(
          planning_application:,
          category: :summary_of_work
        )
      )
    end

    it "renders link to new assessment detail page" do
      expect(page).to have_link(
        "Summary of works",
        href: "/planning_applications/#{planning_application.id}/assessment_details/new?category=summary_of_work"
      )
    end

    it "renders correct status tag" do
      expect(page).to have_content("Not started")
    end
  end

  context "when the assessment needs review" do
    before do
      create(
        :assessment_detail,
        :summary_of_work,
        planning_application:,
        review_status: :complete,
        reviewer_verdict: :rejected
      )

      create(
        :recommendation,
        planning_application:,
        challenged: true,
        status: :review_complete,
        reviewer_comment: "challenged"
      )

      render_inline(
        described_class.new(
          planning_application:,
          category: :summary_of_work
        )
      )
    end

    it "renders link to new assessment detail page" do
      expect(page).to have_link(
        "Summary of works",
        href: "/planning_applications/#{planning_application.id}/assessment_details/new?category=summary_of_work"
      )
    end

    it "renders correct status tag" do
      expect(page).to have_content("To be reviewed")
    end
  end

  context "when the assessment is in progress" do
    let!(:assessment_detail) do
      create(
        :assessment_detail,
        :summary_of_work,
        planning_application:,
        assessment_status: :in_progress
      )
    end

    before do
      render_inline(
        described_class.new(
          planning_application:,
          category: :summary_of_work
        )
      )
    end

    it "renders link to edit assessment detail page" do
      expect(page).to have_link(
        "Summary of works",
        href: "/planning_applications/#{planning_application.id}/assessment_details/#{assessment_detail.id}/edit"
      )
    end

    it "renders correct status tag" do
      expect(page).to have_content("In progress")
    end
  end

  context "when the assessment is complete" do
    let!(:assessment_detail) do
      create(
        :assessment_detail,
        :summary_of_work,
        planning_application:,
        assessment_status: :complete
      )
    end

    before do
      render_inline(
        described_class.new(
          planning_application:,
          category: :summary_of_work
        )
      )
    end

    it "renders link to show assessment detail page" do
      expect(page).to have_link(
        "Summary of works",
        href: "/planning_applications/#{planning_application.id}/assessment_details/#{assessment_detail.id}"
      )
    end

    it "renders correct status tag" do
      expect(page).to have_content("Completed")
    end
  end
end
