# frozen_string_literal: true

require "rails_helper"

RSpec.describe StatusTags::Reviewing::RecommendationComponent, type: :component do
  let(:user) { create(:user, :reviewer) }

  let(:planning_application) do
    create(:planning_application, :awaiting_determination)
  end

  context "when review has not been started" do
    before do
      create(
        :recommendation,
        planning_application:,
        status: :assessment_complete
      )

      render_inline(
        described_class.new(
          planning_application:,
          user:
        )
      )
    end

    it "renders 'Not started' status" do
      expect(page).to have_content("Not started")
    end
  end

  context "when review is complete" do
    before do
      create(
        :recommendation,
        status: :review_complete,
        planning_application:
      )

      render_inline(
        described_class.new(
          planning_application:,
          user:
        )
      )
    end

    it "renders 'Complete' status" do
      expect(page).to have_content("Completed")
    end
  end

  context "when permitted development right has been updated" do
    before do
      create(
        :recommendation,
        planning_application:,
        submitted: true,
        challenged: false
      )

      create(
        :permitted_development_right,
        planning_application:,
        created_at: 1.day.ago,
        status: :to_be_reviewed
      )

      create(
        :permitted_development_right,
        planning_application:,
        review_status: :review_not_started
      )

      render_inline(
        described_class.new(
          planning_application:,
          user:
        )
      )
    end

    it "renders 'Updated' status" do
      expect(page).to have_content("Updated")
    end
  end

  context "when assessment detail has been updated" do
    before do
      create(
        :recommendation,
        planning_application:,
        submitted: true,
        challenged: false
      )

      create(
        :assessment_detail,
        :summary_of_work,
        planning_application:,
        review_status: :complete,
        reviewer_verdict: :rejected
      )

      create(
        :assessment_detail,
        :summary_of_work,
        planning_application:,
        assessment_status: :complete
      )

      render_inline(
        described_class.new(
          planning_application:,
          user:
        )
      )
    end

    it "renders 'Updated' status" do
      expect(page).to have_content("Updated")
    end
  end

  context "when review is in progress" do
    before do
      create(
        :recommendation,
        planning_application:,
        status: :review_in_progress
      )

      render_inline(
        described_class.new(
          planning_application:,
          user:
        )
      )
    end

    it "renders 'In progress' status" do
      expect(page).to have_content("In progress")
    end
  end
end
