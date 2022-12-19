# frozen_string_literal: true

require "rails_helper"

RSpec.describe TaskListItems::ReviewDocumentsComponent, type: :component do
  let(:planning_application) do
    create(
      :planning_application,
      review_documents_for_recommendation_status: :in_progress
    )
  end

  let(:component) do
    described_class.new(planning_application: planning_application)
  end

  before { render_inline(component) }

  it "renders link" do
    expect(page).to have_link(
      "Review documents for recommendation",
      href: "/planning_applications/#{planning_application.id}/review_documents"
    )
  end

  it "renders status" do
    expect(page).to have_content("In progress")
  end
end
