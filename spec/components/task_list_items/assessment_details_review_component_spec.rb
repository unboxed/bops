# frozen_string_literal: true

require "rails_helper"

RSpec.describe TaskListItems::AssessmentDetailsReviewComponent, type: :component do
  let(:planning_application) do
    create(:planning_application, :awaiting_determination)
  end

  before do
    create(
      :assessment_detail,
      review_status: review_status,
      planning_application: planning_application
    )
  end

  context "when the assessment details review is complete" do
    let(:review_status) { :complete }

    before do
      render_inline(
        described_class.new(planning_application: planning_application)
      )
    end

    it "renders link to show assessment details review page" do
      expect(page).to have_link(
        "Review assessment summaries",
        href: "/planning_applications/#{planning_application.id}/assessment_details_review"
      )
    end
  end

  context "when the assessment details review is not complete" do
    let(:review_status) { :in_progress }

    before do
      render_inline(
        described_class.new(planning_application: planning_application)
      )
    end

    it "renders link to edit assessment details review page" do
      expect(page).to have_link(
        "Review assessment summaries",
        href: "/planning_applications/#{planning_application.id}/assessment_details_review/edit"
      )
    end
  end
end
