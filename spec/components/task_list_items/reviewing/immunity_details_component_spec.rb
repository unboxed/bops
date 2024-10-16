# frozen_string_literal: true

require "rails_helper"

RSpec.describe TaskListItems::Reviewing::ImmunityDetailsComponent, type: :component do
  let(:planning_application) { create(:planning_application) }

  let(:immunity_detail) do
    create(
      :immunity_detail,
      planning_application:
    )
  end

  let!(:review_immunity_detail) do
    create(
      :review,
      :evidence,
      owner: immunity_detail,
      reviewed_at: 1.day.ago,
      review_status:
    )
  end

  before do
    render_inline(
      described_class.new(planning_application:)
    )
  end

  context "when review is 'complete'" do
    let(:review_status) { :review_complete }

    it "renders link to permitted development right review page" do
      expect(page).to have_link(
        "Review evidence of immunity",
        href: "/planning_applications/#{planning_application.reference}/review/immunity_details/#{review_immunity_detail.id}"
      )
    end
  end

  context "when review status is not 'complete'" do
    let(:review_status) { :review_in_progress }

    it "renders link to edit permitted development right review page" do
      expect(page).to have_link(
        "Review evidence of immunity",
        href: "/planning_applications/#{planning_application.reference}/review/immunity_details/#{review_immunity_detail.id}/edit"
      )
    end
  end
end
