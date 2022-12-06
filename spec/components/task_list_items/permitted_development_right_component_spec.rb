# frozen_string_literal: true

require "rails_helper"

RSpec.describe TaskListItems::PermittedDevelopmentRightComponent, type: :component do
  let(:planning_application) { create(:planning_application) }

  context "when record does not exist" do
    before do
      render_inline(
        described_class.new(planning_application: planning_application)
      )
    end

    it "renders link to new permitted development right" do
      expect(page).to have_link(
        "Permitted development rights",
        href: "/planning_applications/#{planning_application.id}/permitted_development_rights/new"
      )
    end

    it "renders 'Not started' status" do
      expect(page).to have_content("Not started")
    end
  end

  context "when record exists" do
    let!(:permitted_development_right) do
      create(
        :permitted_development_right,
        planning_application: planning_application,
        status: status
      )
    end

    before do
      render_inline(
        described_class.new(planning_application: planning_application)
      )
    end

    context "when status is 'to_be_reviewed'" do
      let(:status) { :to_be_reviewed }

      it "renders link to new permitted development right" do
        expect(page).to have_link(
          "Permitted development rights",
          href: "/planning_applications/#{planning_application.id}/permitted_development_rights/new"
        )
      end

      it "renders 'To be reviewed' status" do
        expect(page).to have_content("To be reviewed")
      end
    end

    context "when status is 'in_progress'" do
      let(:status) { :in_progress }

      it "renders link to edit permitted development right" do
        expect(page).to have_link(
          "Permitted development rights",
          href: "/planning_applications/#{planning_application.id}/permitted_development_rights/#{permitted_development_right.id}/edit"
        )
      end

      it "renders 'In progress' status" do
        expect(page).to have_content("In progress")
      end
    end

    context "when status is 'checked'" do
      let(:status) { :checked }

      it "renders link to permitted development right" do
        expect(page).to have_link(
          "Permitted development rights",
          href: "/planning_applications/#{planning_application.id}/permitted_development_rights/#{permitted_development_right.id}"
        )
      end

      it "renders 'Checked' status" do
        expect(page).to have_content("Checked")
      end
    end

    context "when status is 'removed'" do
      let(:status) { :removed }

      it "renders link to permitted development right" do
        expect(page).to have_link(
          "Permitted development rights",
          href: "/planning_applications/#{planning_application.id}/permitted_development_rights/#{permitted_development_right.id}"
        )
      end

      it "renders 'Removed' status" do
        expect(page).to have_content("Removed")
      end
    end
  end
end
