# frozen_string_literal: true

require "rails_helper"

RSpec.describe Validation::CheckRedLineBoundaryTask, type: :component do
  let(:task) { described_class.new(planning_application) }

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

    it "renders 'Not started' status tag" do
      expect(task.task_list_status).to be :not_started
    end

    it "renders sitemap link" do
      expect(task.task_list_link).to eq "/planning_applications/#{planning_application.reference}/validation/sitemap"
      expect(task.task_list_link_text).to eq "Check red line boundary"
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
      expect(task.task_list_status).to be :complete
    end

    it "renders sitemap link" do
      expect(task.task_list_link).to eq "/planning_applications/#{planning_application.reference}/validation/sitemap"
      expect(task.task_list_link_text).to eq "Check red line boundary"
    end

    context "when there is a closed change request" do
      let!(:red_line_boundary_change_validation_request) do
        create(
          :red_line_boundary_change_validation_request,
          planning_application:,
          state: :closed
        )
      end

      it "renders 'Valid' status tag" do
        expect(task.task_list_status).to be :complete
      end

      it "renders change request link" do
        expect(task.task_list_link).to eq "/planning_applications/#{planning_application.reference}/validation/red_line_boundary_change_validation_requests/#{red_line_boundary_change_validation_request.id}"
        expect(task.task_list_link_text).to eq "Check red line boundary"
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
      expect(task.task_list_status).to be :complete
    end

    it "renders sitemap link" do
      expect(task.task_list_link).to eq "/planning_applications/#{planning_application.reference}/validation/sitemap"
      expect(task.task_list_link_text).to eq "Check red line boundary"
    end

    context "when there is a closed change request" do
      before do
        create(
          :red_line_boundary_change_validation_request,
          planning_application:,
          state: :closed,
          created_at: 2.days.ago
        )
      end

      it "renders 'Valid' status tag" do
        expect(task.task_list_status).to be :complete
      end

      it "renders change request link" do
        expect(task.task_list_link).to eq "/planning_applications/#{planning_application.reference}/validation/red_line_boundary_change_validation_requests/#{red_line_boundary_change_validation_request.id}"
        expect(task.task_list_link_text).to eq "Check red line boundary"
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

    it "renders 'Invalid' status tag" do
      expect(task.task_list_status).to be :invalid
    end

    it "renders change request link" do
      expect(task.task_list_link).to eq "/planning_applications/#{planning_application.reference}/validation/red_line_boundary_change_validation_requests/#{red_line_boundary_change_validation_request.id}"
      expect(task.task_list_link_text).to eq "Check red line boundary"
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

    it "renders 'Updated' status tag" do
      expect(task.task_list_status).to be :updated
    end

    it "renders change request link" do
      expect(task.task_list_link).to eq "/planning_applications/#{planning_application.reference}/validation/red_line_boundary_change_validation_requests/#{red_line_boundary_change_validation_request.id}"

      expect(task.task_list_link_text).to eq "Check red line boundary"
    end
  end

  context "when boundary_geojson is not present" do
    let(:planning_application) { create(:planning_application) }

    it "does not render link" do
      expect(task.task_list_link).not_to be_present
    end
  end
end
