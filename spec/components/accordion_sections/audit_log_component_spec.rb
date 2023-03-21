# frozen_string_literal: true

require "rails_helper"

RSpec.describe AccordionSections::AuditLogComponent, type: :component do
  let(:planning_application) { create(:planning_application) }

  let(:component) do
    described_class.new(planning_application:)
  end

  it "renders link to audits page" do
    render_inline(component)

    expect(page).to have_link(
      "View all audits",
      href: "/planning_applications/#{planning_application.id}/audits"
    )
  end

  context "when there are audits" do
    let(:user) { create(:user, name: "Alice Smith") }

    before do
      travel_to(DateTime.new(2022, 12, 9, 11))
      planning_application

      travel_to(DateTime.new(2022, 12, 9, 12))

      create(
        :audit,
        planning_application:,
        user:
      )
    end

    it "renders last audit user name" do
      render_inline(component)

      expect(page).to have_content("Alice Smith")
    end

    it "renders last audit created at" do
      render_inline(component)

      expect(page).to have_content("9 December 2022 at 12:00")
    end
  end
end
