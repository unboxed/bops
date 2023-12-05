# frozen_string_literal: true

require "rails_helper"

RSpec.describe TaskListItems::CheckRedLineBoundaryComponent, type: :component do
  let(:component) do
    described_class.new(planning_application:)
  end

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

  context "when there is no change request and valid_red_line_boundary is not set to true" do
    let(:planning_application) do
      create(
        :planning_application,
        boundary_geojson:
      )
    end

    before { render_inline(component) }

    it "renders 'Not started' status tag" do
      expect(page).to have_content("Not started")
    end

    it "renders sitemap link" do
      expect(page).to have_link(
        "Check red line boundary",
        href: "/planning_applications/#{planning_application.id}/validation/sitemap"
      )
    end
  end

  context "when planning application has valid_red_line_boundary set to true" do
    let(:planning_application) do
      create(
        :planning_application,
        valid_red_line_boundary: true,
        boundary_geojson:
      )
    end

    it "renders 'Valid' status tag" do
      render_inline(component)

      expect(page).to have_content("Valid")
    end

    it "renders sitemap link" do
      render_inline(component)

      expect(page).to have_link(
        "Check red line boundary",
        href: "/planning_applications/#{planning_application.id}/validation/sitemap"
      )
    end

    context "when there is a closed change request" do
      let!(:red_line_boundary_change_validation_request) do
        create(
          :red_line_boundary_change_validation_request,
          planning_application:,
          state: :closed
        )
      end

      before { render_inline(component) }

      it "renders 'Valid' status tag" do
        expect(page).to have_content("Valid")
      end

      it "renders change request link" do
        expect(page).to have_link(
          "Check red line boundary",
          href: "/planning_applications/#{planning_application.id}/validation/red_line_boundary_change_validation_requests/#{red_line_boundary_change_validation_request.id}"
        )
      end
    end
  end

  context "when there is an approved change request" do
    let(:planning_application) do
      create(
        :planning_application,
        boundary_geojson:
      )
    end

    let!(:red_line_boundary_change_validation_request) do
      create(
        :red_line_boundary_change_validation_request,
        planning_application:,
        approved: true,
        created_at: 1.day.ago
      )
    end

    it "renders 'Valid' status tag" do
      render_inline(component)

      expect(page).to have_content("Valid")
    end

    it "renders sitemap link" do
      render_inline(component)

      expect(page).to have_link(
        "Check red line boundary",
        href: "/planning_applications/#{planning_application.id}/validation/sitemap"
      )
    end

    context "when there is a closed change request" do
      before do
        create(
          :red_line_boundary_change_validation_request,
          planning_application:,
          state: :closed,
          created_at: 2.days.ago
        )

        render_inline(component)
      end

      it "renders 'Valid' status tag" do
        expect(page).to have_content("Valid")
      end

      it "renders change request link" do
        expect(page).to have_link(
          "Check red line boundary",
          href: "/planning_applications/#{planning_application.id}/validation/red_line_boundary_change_validation_requests/#{red_line_boundary_change_validation_request.id}"
        )
      end
    end
  end

  context "when there is an open change request" do
    let(:planning_application) do
      create(
        :planning_application,
        boundary_geojson:
      )
    end

    let!(:red_line_boundary_change_validation_request) do
      create(
        :red_line_boundary_change_validation_request,
        planning_application:,
        state: :open
      )
    end

    before { render_inline(component) }

    it "renders 'Invalid' status tag" do
      expect(page).to have_content("Invalid")
    end

    it "renders change request link" do
      expect(page).to have_link(
        "Check red line boundary",
        href: "/planning_applications/#{planning_application.id}/validation/red_line_boundary_change_validation_requests/#{red_line_boundary_change_validation_request.id}"
      )
    end
  end

  context "when there is a change request with approved set to false" do
    let(:planning_application) do
      create(
        :planning_application,
        boundary_geojson:
      )
    end

    let!(:red_line_boundary_change_validation_request) do
      create(
        :red_line_boundary_change_validation_request,
        planning_application:,
        approved: false,
        state: :closed,
        rejection_reason: "reason"
      )
    end

    before { render_inline(component) }

    it "renders 'Updated' status tag" do
      expect(page).to have_content("Updated")
    end

    it "renders change request link" do
      expect(page).to have_link(
        "Check red line boundary",
        href: "/planning_applications/#{planning_application.id}/validation/red_line_boundary_change_validation_requests/#{red_line_boundary_change_validation_request.id}"
      )
    end
  end

  context "when boundary_geojson is not present" do
    let(:planning_application) { create(:planning_application) }

    before { render_inline(component) }

    it "does not render link" do
      expect(page).not_to have_link("Check red line boundary")
    end
  end
end
