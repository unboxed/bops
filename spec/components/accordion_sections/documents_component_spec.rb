# frozen_string_literal: true

require "rails_helper"

RSpec.describe AccordionSections::DocumentsComponent, type: :component do
  let(:planning_application) { create(:planning_application) }

  let(:component) do
    described_class.new(planning_application:)
  end

  it "renders link to manage documents" do
    render_inline(component)

    expect(page).to have_link(
      "Manage documents",
      href: "/planning_applications/#{planning_application.id}/documents"
    )
  end

  context "when active document is present" do
    let(:file_path) do
      Rails.root.join("spec/fixtures/images/proposed-floorplan.png")
    end

    let(:file) { Rack::Test::UploadedFile.new(file_path, "image/png") }

    before do
      create(:document, planning_application:, file:)
    end

    it "renders document information" do
      render_inline(component)

      expect(page).to have_content("File name: proposed-floorplan.png")
    end
  end
end
