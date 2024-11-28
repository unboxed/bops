# frozen_string_literal: true

require "rails_helper"

RSpec.describe TaskListItems::Assessment::PermittedDevelopmentRightComponent, type: :component do
  let(:planning_application) { create(:planning_application) }
  subject { described_class.new(planning_application:) }

  context "when assessment has not started" do
    before do
      render_inline(subject)
    end

    it "renders link to permitted development rights page" do
      expect(page).to have_link(
        "Permitted development rights",
        href: "/planning_applications/#{planning_application.reference}/assessment/permitted_development_rights/edit"
      )
    end

    it "renders 'Not started' status" do
      expect(page).to have_content("Not started")
    end
  end

  context "when review is needed" do
    before do
      create(
        :permitted_development_right,
        planning_application:,
        status: :to_be_reviewed,
        review_status: :review_complete,
        accepted: false
      )

      create(
        :recommendation,
        status: :review_complete,
        challenged: true,
        planning_application:,
        reviewer_comment: "comment"
      )

      render_inline(subject)
    end

    it "renders link to permitted development rights page" do
      expect(page).to have_link(
        "Permitted development rights",
        href: "/planning_applications/#{planning_application.reference}/assessment/permitted_development_rights/edit"
      )
    end

    it "renders 'To be reviewed' status" do
      expect(page).to have_content("To be reviewed")
    end
  end

  context "when status is 'in_progress'" do
    let!(:permitted_development_right) do
      create(
        :permitted_development_right,
        planning_application:,
        status: :in_progress
      )
    end

    before do
      render_inline(
        described_class.new(planning_application:)
      )
    end

    it "renders link to edit permitted development rights page" do
      expect(page).to have_link(
        "Permitted development rights",
        href: "/planning_applications/#{planning_application.reference}/assessment/permitted_development_rights/edit"
      )
    end

    it "renders 'In progress' status" do
      expect(page).to have_content("In progress")
    end
  end

  context "when status is 'complete'" do
    let!(:permitted_development_right) do
      create(
        :permitted_development_right,
        planning_application:,
        status: :complete
      )
    end

    before do
      render_inline(subject)
    end

    it "renders link to permitted development rights page" do
      expect(page).to have_link(
        "Permitted development rights",
        href: "/planning_applications/#{planning_application.reference}/assessment/permitted_development_rights"
      )
    end

    it "renders 'Completed' status" do
      expect(page).to have_content("Completed")
    end
  end

  context "when status is 'removed'" do
    let!(:permitted_development_right) do
      create(:permitted_development_right, :removed, planning_application:)
    end

    before do
      render_inline(subject)
    end

    it "renders link to permitted development rights page" do
      expect(page).to have_link(
        "Permitted development rights",
        href: "/planning_applications/#{planning_application.reference}/assessment/permitted_development_rights"
      )
    end

    it "renders 'Removed' status" do
      expect(page).to have_content("Removed")
    end
  end
end
