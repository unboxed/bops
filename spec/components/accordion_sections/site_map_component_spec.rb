# frozen_string_literal: true

require "rails_helper"

RSpec.describe AccordionSections::SiteMapComponent, type: :component do
  let(:component) do
    described_class.new(planning_application: planning_application)
  end

  context "when planning application is validated" do
    let(:planning_application) { create(:planning_application, :in_assessment) }

    it "has link to new change request" do
      render_inline(component)

      expect(page).to have_link(
        "Request approval for a change to red line boundary",
        href: "/planning_applications/#{planning_application.id}/red_line_boundary_change_validation_requests/new"
      )
    end

    context "when change request is present and open" do
      let!(:red_line_boundary_change_validation_request) do
        create(
          :red_line_boundary_change_validation_request,
          planning_application: planning_application,
          post_validation: true,
          state: :open
        )
      end

      it "has link to view request" do
        render_inline(component)

        expect(page).to have_link(
          "View requested red line boundary change",
          href: "/planning_applications/#{planning_application.id}/red_line_boundary_change_validation_requests/#{red_line_boundary_change_validation_request.id}"
        )
      end
    end

    context "when change request is present and closed" do
      let!(:red_line_boundary_change_validation_request) do
        create(
          :red_line_boundary_change_validation_request,
          planning_application: planning_application,
          post_validation: true,
          state: :closed
        )
      end

      it "has link to view applicant response" do
        render_inline(component)

        expect(page).to have_link(
          "View applicants response to requested red line boundary change",
          href: "/planning_applications/#{planning_application.id}/red_line_boundary_change_validation_requests/#{red_line_boundary_change_validation_request.id}"
        )
      end
    end
  end

  context "when there is no digital site map" do
    let(:planning_application) { create(:planning_application) }

    it "renders 'no digital site map' message" do
      render_inline(component)

      expect(page).to have_content("No digital site map provided")
    end
  end

  context "when digital site map is present" do
    let(:boundary_geojson) do
      {
        type: "Feature",
        properties: {},
        geometry: {
          type: "Polygon",
          coordinates: [
            [
              [-0.054597, 51.537331],
              [-0.054588, 51.537287],
              [-0.054453, 51.537313],
              [-0.054597, 51.537331]
            ]
          ]
        }
      }.to_json
    end

    let(:planning_application) do
      create(
        :planning_application,
        boundary_geojson: boundary_geojson,
        updated_address_or_boundary_geojson: updated_address_or_boundary_geojson,
        boundary_created_by: boundary_created_by
      )
    end

    let(:updated_address_or_boundary_geojson) { false }
    let(:boundary_created_by) { nil }

    it "renders 'site map drawn by applicant'" do
      render_inline(component)

      expect(page).to have_content("Site map drawn by applicant")
    end

    context "when user is assigned to 'boundary_created_by'" do
      let(:user) { create(:user, name: "Alice Smith") }
      let(:boundary_created_by) { user }

      it "renders 'site map drawn by user'" do
        render_inline(component)

        expect(page).to have_content("Site map drawn by Alice Smith")
      end
    end

    context "when 'updated_address_or_boundary_geojson' is true" do
      let(:updated_address_or_boundary_geojson) { true }

      it "renders warning message" do
        render_inline(component)

        expect(page).to have_content("This application has been updated. Please check the site map is correct.")
      end
    end
  end
end
