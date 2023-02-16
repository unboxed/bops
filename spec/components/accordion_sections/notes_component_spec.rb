# frozen_string_literal: true

require "rails_helper"

RSpec.describe AccordionSections::NotesComponent, type: :component do
  let(:planning_application) { create(:planning_application) }

  let(:component) do
    described_class.new(planning_application:)
  end

  it "renders link to add note" do
    render_inline(component)

    expect(page).to have_link(
      "Add a note",
      href: "/planning_applications/#{planning_application.id}/notes"
    )
  end

  context "when there is a note" do
    let(:entry) do
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat."
    end

    before do
      create(
        :note,
        planning_application:,
        created_at: DateTime.new(2022, 12, 11, 12),
        entry:
      )

      render_inline(component)
    end

    it "renders note entry" do
      expect(page).to have_content(
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi u..."
      )
    end

    it "renders note created at" do
      expect(page).to have_content("11 December 2022 12:00")
    end

    it "renders link to add and view notes" do
      expect(page).to have_link(
        "Add and view all notes",
        href: "/planning_applications/#{planning_application.id}/notes"
      )
    end
  end
end
