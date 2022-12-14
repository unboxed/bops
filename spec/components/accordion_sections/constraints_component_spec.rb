# frozen_string_literal: true

require "rails_helper"

RSpec.describe AccordionSections::ConstraintsComponent, type: :component do
  let(:planning_application) do
    create(
      :planning_application,
      updated_address_or_boundary_geojson: updated_address_or_boundary_geojson,
      feedback: feedback
    )
  end

  let(:updated_address_or_boundary_geojson) { false }
  let(:feedback) { {} }

  let(:component) do
    described_class.new(planning_application: planning_application)
  end

  context "when 'updated_address_or_boundary_geojson' is true" do
    let(:updated_address_or_boundary_geojson) { true }

    it "renders warning message" do
      render_inline(component)

      expect(page).to have_content(
        "This application has been updated. Please check the constraints are correct."
      )
    end
  end

  context "when feedback is present" do
    let(:feedback) do
      { planning_constraints: "feedback" }
    end

    before { render_inline(component) }

    it "renders feedback" do
      expect(page).to have_content("feedback")
    end

    it "renders warning message" do
      expect(page).to have_content(
        "The applicant or agent believes the constraints are inaccurate."
      )
    end
  end
end
