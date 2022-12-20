# frozen_string_literal: true

require "rails_helper"

RSpec.describe TaskListItems::ValidationDecisionComponent, type: :component do
  let(:planning_application) { create(:planning_application) }

  let(:component) do
    described_class.new(planning_application: planning_application)
  end

  before { render_inline(component) }

  it "renders status" do
    expect(page).to have_content("Valid")
  end

  it "renders link" do
    expect(page).to have_link(
      "Send validation decision",
      href: "/planning_applications/#{planning_application.id}/validation_decision"
    )
  end

  context "when application is not started" do
    let(:planning_application) { create(:planning_application, :not_started) }

    it "renders status" do
      expect(page).to have_content("Not started")
    end
  end

  context "when application is invalidated" do
    let(:planning_application) { create(:planning_application, :invalidated) }

    it "renders status" do
      expect(page).to have_content("Invalid")
    end
  end
end
