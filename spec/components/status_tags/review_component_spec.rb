# frozen_string_literal: true

require "rails_helper"

RSpec.describe StatusTags::ReviewComponent, type: :component do
  let(:planning_application) { create(:planning_application) }

  context "when permitted development right has been updated" do
    before do
      create(
        :permitted_development_right,
        review_status: :review_not_started,
        planning_application:,
        created_at: 1.day.ago,
        status: :to_be_reviewed
      )

      create(
        :recommendation,
        planning_application:,
        submitted: true
      )

      render_inline(
        described_class.new(
          review_item: permitted_development_right,
          updated: true
        )
      )
    end

    let(:permitted_development_right) do
      create(
        :permitted_development_right,
        review_status: :review_not_started,
        planning_application:
      )
    end

    it "renders 'Updated' status" do
      expect(page).to have_content("Updated")
    end
  end

  context "when review_status is 'review_complete'" do
    let(:permitted_development_right) do
      create(
        :permitted_development_right,
        review_status: :review_complete,
        planning_application:
      )
    end

    before do
      render_inline(
        described_class.new(
          review_item: permitted_development_right
        )
      )
    end

    it "renders 'Complete' status" do
      expect(page).to have_content("Completed")
    end
  end

  context "when review_status is 'review_in_progress'" do
    let(:permitted_development_right) do
      create(
        :permitted_development_right,
        review_status: :review_in_progress,
        planning_application:
      )
    end

    before do
      render_inline(
        described_class.new(
          review_item: permitted_development_right
        )
      )
    end

    it "renders 'In progress' status" do
      expect(page).to have_content("In progress")
    end
  end

  context "when review_status is 'review_not_started'" do
    let(:permitted_development_right) do
      create(
        :permitted_development_right,
        review_status: :review_not_started,
        planning_application:
      )
    end

    before do
      render_inline(
        described_class.new(
          review_item: permitted_development_right
        )
      )
    end

    it "renders 'Not started' status" do
      expect(page).to have_content("Not started")
    end
  end
end
