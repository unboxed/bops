# frozen_string_literal: true

require "rails_helper"

RSpec.describe StatusTags::AdditionalDocumentComponent, type: :component do
  let(:planning_application) { create(:planning_application) }

  let(:component) do
    described_class.new(planning_application: planning_application)
  end

  it "renders 'Not started' status" do
    render_inline(component)

    expect(page).to have_content("Not started")
  end

  context "when there is an open request" do
    before do
      create(
        :additional_document_validation_request,
        planning_application: planning_application
      )
    end

    it "renders 'Invalid' status" do
      render_inline(component)

      expect(page).to have_content("Invalid")
    end
  end

  context "when 'documents_missing' is false" do
    let(:planning_application) do
      create(:planning_application, documents_missing: false)
    end

    it "renders 'Valid' status" do
      render_inline(component)

      expect(page).to have_content("Valid")
    end
  end
end
