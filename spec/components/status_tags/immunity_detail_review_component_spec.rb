# frozen_string_literal: true

require "rails_helper"

RSpec.describe StatusTags::ImmunityDetailReviewComponent, type: :component do
  let(:planning_application) { create(:planning_application) }

  context "when review_status is 'review_complete'" do
    let(:immunity_detail) do
      create(
        :immunity_detail,
        review_status: :review_complete,
        planning_application:
      )
    end

    before do
      render_inline(
        described_class.new(
          immunity_detail:,
          planning_application:
        )
      )
    end

    it "renders 'Complete' status" do
      expect(page).to have_content("Completed")
    end
  end

  context "when review_status is 'review_in_progress'" do
    let(:immunity_detail) do
      create(
        :immunity_detail,
        review_status: :review_in_progress,
        planning_application:
      )
    end

    before do
      render_inline(
        described_class.new(
          immunity_detail:,
          planning_application:
        )
      )
    end

    it "renders 'In progress' status" do
      expect(page).to have_content("In progress")
    end
  end

  context "when review_status is 'review_not_started'" do
    let(:immunity_detail) do
      create(
        :immunity_detail,
        review_status: :review_not_started,
        planning_application:
      )
    end

    before do
      render_inline(
        described_class.new(
          immunity_detail:,
          planning_application:
        )
      )
    end

    it "renders 'Not started' status" do
      expect(page).to have_content("Not started")
    end
  end
end
