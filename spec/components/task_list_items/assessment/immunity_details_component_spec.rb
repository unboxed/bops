# frozen_string_literal: true

require "rails_helper"

RSpec.describe TaskListItems::Assessment::ImmunityDetailsComponent, type: :component do
  let(:planning_application) { create(:planning_application, :with_immunity) }
  let!(:review) { create(:review, owner: planning_application.immunity_detail, specific_attributes: {review_type: "evidence"}) }

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
        href: "/planning_applications/#{planning_application.id}/assessment/immunity_details/new"
      )
    end

    it "renders correct status tag" do
      expect(page).to have_content("Not started")
    end
  end

  context "when review status is 'complete'" do
    before do
      planning_application.immunity_detail.current_evidence_review_immunity_detail.update(status: "complete")
      render_inline(
        described_class.new(
          planning_application:
        )
      )
    end

    it "renders link to permitted development right review page" do
      expect(page).to have_link(
        "Evidence of immunity",
        href: "/planning_applications/#{planning_application.id}/assessment/immunity_details/#{planning_application.immunity_detail.id}"
      )
    end

    it "renders correct status tag" do
      expect(page).to have_content("Complete")
    end
  end

  context "when review status is not 'complete'" do
    before do
      planning_application.immunity_detail.current_evidence_review_immunity_detail.update(status: "in_progress")

      render_inline(
        described_class.new(
          planning_application:
        )
      )
    end

    it "renders link to edit permitted development right review page" do
      expect(page).to have_link(
        "Evidence of immunity",
        href: "/planning_applications/#{planning_application.id}/assessment/immunity_details/#{planning_application.immunity_detail.id}/edit"
      )
    end

    it "renders correct status tag" do
      expect(page).to have_content("In progress")
    end
  end
end
