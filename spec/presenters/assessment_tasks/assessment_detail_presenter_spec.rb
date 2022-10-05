# frozen_string_literal: true

require "rails_helper"

RSpec.describe AssessmentTasks::AssessmentDetailPresenter, type: :presenter do
  include ActionView::TestCase::Behavior

  subject(:presenter) { described_class.new(view, planning_application, category) }

  let(:context) { ActionView::Base.new }
  let!(:planning_application) { create(:planning_application, :in_assessment) }

  context "when summary of works" do
    let(:category) { "summary_of_work" }

    describe "#task_list_row" do
      context "when not started" do
        it "the task list row shows invalid status html" do
          html = presenter.task_list_row

          expect(html).to include("app-task-list__task-name")

          expect(html).to include(
            link_to(
              "Summary of works",
              new_planning_application_assessment_detail_path(planning_application, category: "summary_of_work"),
              class: "govuk-link"
            )
          )

          expect(html).to include(
            "<strong class=\"govuk-tag govuk-tag--grey app-task-list__task-tag\">Not started</strong>"
          )
        end
      end

      context "when completed" do
        let!(:summary_of_work) { create(:assessment_detail, :summary_of_work, planning_application: planning_application) }

        it "the task list row shows invalid status html" do
          html = presenter.task_list_row

          expect(html).to include("app-task-list__task-name")

          expect(html).to include(
            link_to(
              "Summary of works",
              planning_application_assessment_detail_path(planning_application, summary_of_work),
              class: "govuk-link"
            )
          )

          expect(html).to include(
            "<strong class=\"govuk-tag govuk-tag--blue app-task-list__task-tag\">Completed</strong>"
          )
        end
      end

      context "when in progress" do
        let!(:summary_of_work) { create(:assessment_detail, :summary_of_work, :in_progress, planning_application: planning_application) }

        it "the task list row shows invalid status html" do
          html = presenter.task_list_row

          expect(html).to include("app-task-list__task-name")

          expect(html).to include(
            link_to(
              "Summary of works",
              edit_planning_application_assessment_detail_path(planning_application, summary_of_work),
              class: "govuk-link"
            )
          )

          expect(html).to include(
            "<strong class=\"govuk-tag app-task-list__task-tag\">In progress</strong>"
          )
        end
      end
    end
  end

  context "when additional evidence" do
    let(:category) { "additional_evidence" }

    describe "#task_list_row" do
      context "when not started" do
        it "the task list row shows invalid status html" do
          html = presenter.task_list_row

          expect(html).to include("app-task-list__task-name")

          expect(html).to include(
            link_to(
              "Additional evidence",
              new_planning_application_assessment_detail_path(planning_application, category: "additional_evidence"),
              class: "govuk-link"
            )
          )

          expect(html).to include(
            "<strong class=\"govuk-tag govuk-tag--grey app-task-list__task-tag\">Not started</strong>"
          )
        end
      end

      context "when completed" do
        let!(:additional_evidence) { create(:assessment_detail, :additional_evidence, planning_application: planning_application) }

        it "the task list row shows invalid status html" do
          html = presenter.task_list_row

          expect(html).to include("app-task-list__task-name")

          expect(html).to include(
            link_to(
              "Additional evidence",
              planning_application_assessment_detail_path(planning_application, additional_evidence),
              class: "govuk-link"
            )
          )

          expect(html).to include(
            "<strong class=\"govuk-tag govuk-tag--blue app-task-list__task-tag\">Completed</strong>"
          )
        end
      end

      context "when in progress" do
        let!(:additional_evidence) { create(:assessment_detail, :additional_evidence, :in_progress, planning_application: planning_application) }

        it "the task list row shows invalid status html" do
          html = presenter.task_list_row

          expect(html).to include("app-task-list__task-name")

          expect(html).to include(
            link_to(
              "Additional evidence",
              edit_planning_application_assessment_detail_path(planning_application, additional_evidence),
              class: "govuk-link"
            )
          )

          expect(html).to include(
            "<strong class=\"govuk-tag app-task-list__task-tag\">In progress</strong>"
          )
        end
      end
    end
  end

  context "when site description" do
    let(:category) { "site_description" }

    describe "#task_list_row" do
      context "when not started" do
        it "the task list row shows invalid status html" do
          html = presenter.task_list_row

          expect(html).to include("app-task-list__task-name")

          expect(html).to include(
            link_to(
              "Site description",
              new_planning_application_assessment_detail_path(planning_application, category: "site_description"),
              class: "govuk-link"
            )
          )

          expect(html).to include(
            "<strong class=\"govuk-tag govuk-tag--grey app-task-list__task-tag\">Not started</strong>"
          )
        end
      end

      context "when completed" do
        let!(:site_description) { create(:assessment_detail, :site_description, planning_application: planning_application) }

        it "the task list row shows invalid status html" do
          html = presenter.task_list_row

          expect(html).to include("app-task-list__task-name")

          expect(html).to include(
            link_to(
              "Site description",
              planning_application_assessment_detail_path(planning_application, site_description),
              class: "govuk-link"
            )
          )

          expect(html).to include(
            "<strong class=\"govuk-tag govuk-tag--blue app-task-list__task-tag\">Completed</strong>"
          )
        end
      end

      context "when in progress" do
        let!(:site_description) { create(:assessment_detail, :site_description, :in_progress, planning_application: planning_application) }

        it "the task list row shows invalid status html" do
          html = presenter.task_list_row

          expect(html).to include("app-task-list__task-name")

          expect(html).to include(
            link_to(
              "Site description",
              edit_planning_application_assessment_detail_path(planning_application, site_description),
              class: "govuk-link"
            )
          )

          expect(html).to include(
            "<strong class=\"govuk-tag app-task-list__task-tag\">In progress</strong>"
          )
        end
      end
    end
  end
end
