# frozen_string_literal: true

require "rails_helper"

RSpec.describe AssessmentTasks::SummaryOfWorksPresenter, type: :presenter do
  include ActionView::TestCase::Behavior

  subject(:presenter) { described_class.new(view, planning_application) }

  let(:context) { ActionView::Base.new }
  let!(:planning_application) { create(:planning_application, :in_assessment) }

  describe "#task_list_row" do
    context "when summary of works has not been started" do
      it "the task list row shows invalid status html" do
        html = presenter.task_list_row

        expect(html).to include("app-task-list__task-name")

        expect(html).to include(
          link_to(
            "Summary of works",
            new_planning_application_summary_of_work_path(planning_application),
            class: "govuk-link"
          )
        )

        expect(html).to include(
          "<strong class=\"govuk-tag govuk-tag--grey app-task-list__task-tag\">Not started</strong>"
        )
      end
    end

    context "when summary of works has been completed" do
      let!(:summary_of_work) { create(:summary_of_work, planning_application: planning_application) }

      it "the task list row shows invalid status html" do
        html = presenter.task_list_row

        expect(html).to include("app-task-list__task-name")

        expect(html).to include(
          link_to(
            "Summary of works",
            planning_application_summary_of_work_path(planning_application, summary_of_work),
            class: "govuk-link"
          )
        )

        expect(html).to include(
          "<strong class=\"govuk-tag govuk-tag--blue app-task-list__task-tag\">Completed</strong>"
        )
      end
    end

    context "when summary of works is in progress" do
      let!(:summary_of_work) { create(:summary_of_work, :in_progress, planning_application: planning_application) }

      it "the task list row shows invalid status html" do
        html = presenter.task_list_row

        expect(html).to include("app-task-list__task-name")

        expect(html).to include(
          link_to(
            "Summary of works",
            edit_planning_application_summary_of_work_path(planning_application, summary_of_work),
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
