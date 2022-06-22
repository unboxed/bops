# frozen_string_literal: true

require "rails_helper"

RSpec.describe ValidationTasks::RedLineBoundaryPresenter, type: :presenter do
  include ActionView::TestCase::Behavior

  subject(:presenter) { described_class.new(view, planning_application) }

  let(:context) { ActionView::Base.new }
  let!(:planning_application) { create(:planning_application, :invalidated, :with_boundary_geojson, valid_red_line_boundary: valid_red_line_boundary) }

  describe "#task_list_row" do
    context "when red line boundary is invalid" do
      let(:valid_red_line_boundary) { false }
      let!(:red_line_boundary_change_validation_request) do
        create(:red_line_boundary_change_validation_request, planning_application: planning_application)
      end

      it "the task list row shows invalid status html" do
        html = presenter.task_list_row

        expect(html).to include("app-task-list__task-name")
        expect(html).to include("Check red line boundary")
        expect(html).to include(
          "/planning_applications/#{planning_application.id}/red_line_boundary_change_validation_requests/#{red_line_boundary_change_validation_request.id}"
        )
        expect(html).to include(
          "<strong class=\"govuk-tag govuk-tag--red app-task-list__task-tag\">Invalid</strong>"
        )
      end
    end

    context "when red line boundary is valid" do
      let(:valid_red_line_boundary) { true }

      it "the task list row shows valid status html" do
        html = presenter.task_list_row

        expect(html).to include("app-task-list__task-name")
        expect(html).to include("Check red line boundary")
        expect(html).to include(
          "/planning_applications/#{planning_application.id}/sitemap"
        )
        expect(html).to include(
          "<strong class=\"govuk-tag govuk-tag--green app-task-list__task-tag\">Valid</strong>"
        )
      end

      context "with applicant confirming red line boundary changes" do
        let!(:red_line_boundary_change_validation_request) do
          create(:red_line_boundary_change_validation_request, :closed, approved: true, planning_application: planning_application)
        end

        it "the task list row shows an valid status html" do
          html = presenter.task_list_row

          expect(html).to include("app-task-list__task-name")
          expect(html).to include("Check red line boundary")
          expect(html).to include(
            "/planning_applications/#{planning_application.id}/red_line_boundary_change_validation_requests/#{red_line_boundary_change_validation_request.id}"
          )
          expect(html).to include(
            "<strong class=\"govuk-tag govuk-tag--green app-task-list__task-tag\">Valid</strong>"
          )
        end
      end
    end

    context "when red line boundary is not checked yet" do
      let(:valid_red_line_boundary) { false }

      it "the task list row shows not checked yet status html" do
        html = presenter.task_list_row

        expect(html).to include("app-task-list__task-name")
        expect(html).to include("Check red line boundary")
        expect(html).to include(
          "/planning_applications/#{planning_application.id}/sitemap"
        )
        expect(html).to include(
          "<strong class=\"govuk-tag govuk-tag--grey app-task-list__task-tag\">Not checked yet</strong>"
        )
      end
    end

    context "when red line boundary is updated (i.e. there is a response from the applicant)" do
      let(:valid_red_line_boundary) { false }

      let!(:red_line_boundary_change_validation_request) do
        create(:red_line_boundary_change_validation_request, :closed, approved: false, rejection_reason: "rejected", planning_application: planning_application)
      end

      it "the task list row shows an updated status html" do
        html = presenter.task_list_row

        expect(html).to include("app-task-list__task-name")
        expect(html).to include("Check red line boundary")
        expect(html).to include(
          "/planning_applications/#{planning_application.id}/red_line_boundary_change_validation_requests/#{red_line_boundary_change_validation_request.id}"
        )
        expect(html).to include(
          "<strong class=\"govuk-tag govuk-tag--yellow app-task-list__task-tag\">Updated</strong>"
        )
      end
    end
  end
end
