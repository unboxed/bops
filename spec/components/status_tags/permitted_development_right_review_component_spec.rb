# frozen_string_literal: true

require "rails_helper"

RSpec.describe StatusTags::PermittedDevelopmentRightReviewComponent, type: :component do
  let(:permitted_development_right) do
    build(:permitted_development_right, review_status: review_status)
  end

  before do
    render_inline(
      described_class.new(
        permitted_development_right: permitted_development_right
      )
    )
  end

  context "when review_status is 'review_complete'" do
    let(:review_status) { :review_complete }

    it "renders 'Complete' status" do
      expect(page).to have_content("Complete")
    end
  end

  context "when review_status is 'review_in_progress'" do
    let(:review_status) { :review_in_progress }

    it "renders 'In progress' status" do
      expect(page).to have_content("In progress")
    end
  end

  context "when review_status is 'review_not_started'" do
    let(:review_status) { :review_not_started }

    it "renders 'Not started' status" do
      expect(page).to have_content("Not started")
    end
  end
end
