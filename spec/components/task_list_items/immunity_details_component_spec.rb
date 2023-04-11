# frozen_string_literal: true

require "rails_helper"

RSpec.describe TaskListItems::ImmunityDetailsComponent, type: :component do
  let(:planning_application) { create(:planning_application) }

  context "when the assessment has not been started" do
    before do
      render_inline(
        described_class.new(
          planning_application:
        )
      )
    end

    it "renders link to new assessment detail page" do
      expect(page).to have_link(
        "Evidence of immunity",
        href: "/planning_applications/#{planning_application.id}/immunity_details/new"
      )
    end

    it "renders correct status tag" do
      expect(page).to have_content("Not started")
    end
  end

  context "when review status is 'complete'" do
    let(:review_status) { :review_complete }

    it "renders link to permitted development right review page" do
      expect(page).to have_link(
        "Evidence of immunity",
        href: "/planning_applications/#{planning_application.id}/immunity_details"
      )
    end
  end

  context "when review status is not 'complete'" do
    let(:review_status) { :review_in_progress }

    it "renders link to edit permitted development right review page" do
      expect(page).to have_link(
        "Evidence of immunity",
        href: "/planning_applications/#{planning_application.id}/immunity_details/edit"
      )
    end
  end
end
