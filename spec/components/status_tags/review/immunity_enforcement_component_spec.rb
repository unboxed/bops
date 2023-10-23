# frozen_string_literal: true

require "rails_helper"

RSpec.describe StatusTags::Review::ImmunityEnforcementComponent, type: :component do
  let(:planning_application) { create(:planning_application) }

  context "when review is complete" do
    let(:immunity_detail) do
      create(
        :immunity_detail,
        planning_application:
      )
    end

    let(:review_immunity_detail) do
      create(
        :review_immunity_detail,
        immunity_detail:,
        review_status: :review_complete,
        reviewed_at: 1.day.ago
      )
    end

    before do
      render_inline(
        described_class.new(
          review_immunity_detail:,
          planning_application:
        )
      )
    end

    it "renders 'Complete' status" do
      expect(page).to have_content("Completed")
    end
  end

  context "when review is in progress" do
    let(:immunity_detail) do
      create(
        :immunity_detail,
        planning_application:
      )
    end

    let(:review_immunity_detail) do
      create(
        :review_immunity_detail,
        immunity_detail:,
        review_status: :review_in_progress,
        reviewed_at: 1.day.ago
      )
    end

    before do
      render_inline(
        described_class.new(
          review_immunity_detail:,
          planning_application:
        )
      )
    end

    it "renders 'In progress' status" do
      expect(page).to have_content("In progress")
    end
  end

  context "when review is not started" do
    let(:immunity_detail) do
      create(
        :immunity_detail,
        planning_application:
      )
    end

    let(:review_immunity_detail) do
      create(
        :review_immunity_detail,
        immunity_detail:,
        review_status: :review_not_started
      )
    end

    before do
      render_inline(
        described_class.new(
          review_immunity_detail:,
          planning_application:
        )
      )
    end

    it "renders 'Not started' status" do
      expect(page).to have_content("Not started")
    end
  end
end
