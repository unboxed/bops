# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Check red line boundary task", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user, local_authority:) }
  let(:task) { planning_application.case_record.find_task_by_slug_path!("check-and-validate/check-application-details/check-red-line-boundary") }
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
    }
  end
  let(:new_geojson) do
    {
      type: "Feature",
      properties: {},
      geometry: {
        type: "Polygon",
        coordinates: [
          [
            [-0.054600, 51.537335],
            [-0.054590, 51.537290],
            [-0.054455, 51.537315],
            [-0.054600, 51.537335]
          ]
        ]
      }
    }
  end
  let(:planning_application) { create(:planning_application, :pre_application, :not_started, local_authority:, boundary_geojson:) }

  it_behaves_like "check red line boundary task", :pre_application

  context "pre_application-specific features" do
    before do
      sign_in(user)
      visit "/planning_applications/#{planning_application.reference}/validation/tasks"
    end

    it "hides save button when application is determined" do
      planning_application.update!(status: "determined", determined_at: Time.current)

      within :sidebar do
        click_link "Check red line boundary"
      end

      expect(page).not_to have_button("Save and mark as complete")
    end

    context "when applicant responds to red line boundary change request" do
      let!(:validation_request) do
        create(:red_line_boundary_change_validation_request,
          :open,
          planning_application:,
          reason: "Boundary needs to include garage",
          new_geojson: new_geojson,
          original_geojson: boundary_geojson)
      end

      before do
        task.complete!
        planning_application.update!(status: "invalidated")
      end

      it "sets task to action_required when applicant approves the request" do
        expect(task.reload).to be_completed

        validation_request.update!(approved: true)
        validation_request.close!

        expect(task.reload).to be_action_required
      end

      it "sets task to action_required when applicant rejects the request" do
        expect(task.reload).to be_completed

        validation_request.update!(approved: false, rejection_reason: "The garage is not part of my property")
        validation_request.close!

        expect(task.reload).to be_action_required
      end
    end
  end
end
