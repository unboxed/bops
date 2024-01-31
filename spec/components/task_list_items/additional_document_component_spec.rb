# frozen_string_literal: true

require "rails_helper"

RSpec.describe TaskListItems::AdditionalDocumentComponent, type: :component do
  let(:planning_application) { create(:planning_application) }

  let(:component) do
    described_class.new(planning_application:)
  end

  before { render_inline(component) }

  it "renders link" do
    expect(page).to have_link(
      "Check provided documents",
      href: "/planning_applications/#{planning_application.id}/validation_documents"
    )
  end
end
