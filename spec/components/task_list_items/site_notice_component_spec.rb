# frozen_string_literal: true

require "rails_helper"

RSpec.describe TaskListItems::SiteNoticeComponent, type: :component do
  let(:application_type) do
    create(:application_type, :planning_permission)
  end

  let(:planning_application) do
    create(:planning_application, application_type:)
  end

  let(:component) do
    described_class.new(planning_application:)
  end

  context "when a site notice has not been created before" do
    before { render_inline(component) }

    it "renders 'Not started' status" do
      expect(page).to have_content("Not started")
    end

    it "renders link to new site notice" do
      expect(page).to have_link(
        "Send site notice",
        href: "/planning_applications/#{planning_application.id}/site_notices/new"
      )
    end
  end

  context "when there is a previous site notice" do
    before do
      create(:site_notice, planning_application:)
      render_inline(component)
    end

    it "renders 'Completed' status" do
      expect(page).to have_content("Completed")
    end

    it "renders link to new site notice" do
      expect(page).to have_link(
        "Send site notice",
        href: "/planning_applications/#{planning_application.id}/site_notices/new"
      )
    end
  end
end
