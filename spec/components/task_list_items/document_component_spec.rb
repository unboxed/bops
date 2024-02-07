# frozen_string_literal: true

require "rails_helper"

RSpec.describe TaskListItems::DocumentComponent, type: :component do
  let(:planning_application) { create(:planning_application) }

  let(:component) do
    described_class.new(
      planning_application:,
      document:
    )
  end

  context "when document is validated" do
    let(:document) { create(:document, validated: true) }

    before { render_inline(component) }

    it "renders 'Valid' status" do
      expect(page).to have_content("Valid")
    end

    it "renders link" do
      expect(page).to have_link(
        "proposed-floorplan.png",
        href: "/planning_applications/#{planning_application.id}/documents/#{document.id}/edit?validate=yes"
      )
    end
  end

  context "when there is an open request" do
    let(:document) { create(:document) }

    let!(:replacement_document_validation_request) do
      create(
        :replacement_document_validation_request,
        old_document: document
      )
    end

    before { render_inline(component) }

    it "renders 'Invalid' status" do
      expect(page).to have_content("Invalid")
    end

    it "renders link" do
      expect(page).to have_link(
        "proposed-floorplan.png",
        href: "/planning_applications/#{planning_application.id}/validation/replacement_document_validation_requests/#{replacement_document_validation_request.id}"
      )
    end
  end

  context "when the document is a replacement" do
    let(:document) { create(:document) }

    before do
      create(
        :replacement_document_validation_request,
        new_document: document
      )

      render_inline(component)
    end

    it "renders 'Updated' status" do
      expect(page).to have_content("Updated")
    end

    it "renders link" do
      expect(page).to have_link(
        "proposed-floorplan.png",
        href: "/planning_applications/#{planning_application.id}/documents/#{document.id}/edit?validate=yes"
      )
    end
  end

  context "when task has not been started" do
    let(:document) { create(:document) }

    before do
      render_inline(component)
    end

    it "renders 'Not started' status" do
      expect(page).to have_content("Not started")
    end

    it "renders link" do
      expect(page).to have_link(
        "proposed-floorplan.png",
        href: "/planning_applications/#{planning_application.id}/documents/#{document.id}/edit?validate=yes"
      )
    end
  end
end
