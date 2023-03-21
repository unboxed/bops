# frozen_string_literal: true

require "rails_helper"

RSpec.describe TaskListItems::PermittedDevelopmentRightReviewComponent, type: :component do
  let(:planning_application) { create(:planning_application) }

  let!(:permitted_development_right) do
    create(
      :permitted_development_right,
      review_status:,
      planning_application:
    )
  end

  before do
    render_inline(
      described_class.new(planning_application:)
    )
  end

  context "when review status is 'complete'" do
    let(:review_status) { :review_complete }

    it "renders link to permitted development right review page" do
      expect(page).to have_link(
        "Permitted development rights",
        href: "/planning_applications/#{planning_application.id}/review_permitted_development_rights/#{permitted_development_right.id}"
      )
    end
  end

  context "when review status is not 'complete'" do
    let(:review_status) { :review_in_progress }

    it "renders link to edit permitted development right review page" do
      expect(page).to have_link(
        "Permitted development rights",
        href: "/planning_applications/#{planning_application.id}/review_permitted_development_rights/#{permitted_development_right.id}/edit"
      )
    end
  end
end
