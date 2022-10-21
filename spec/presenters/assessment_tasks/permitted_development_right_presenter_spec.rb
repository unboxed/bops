# frozen_string_literal: true

require "rails_helper"

RSpec.describe AssessmentTasks::PermittedDevelopmentRightPresenter, type: :presenter do
  include ActionView::TestCase::Behavior

  subject(:presenter) { described_class.new(view, planning_application) }

  let(:context) { ActionView::Base.new }
  let!(:planning_application) { create(:planning_application, :in_assessment) }

  describe "#task_list_row" do
    context "when not started" do
      it "the task list row shows invalid status html" do
        html = presenter.task_list_row

        expect(html).to include("app-task-list__task-name")

        expect(html).to include(
          link_to(
            "Permitted development rights",
            new_planning_application_permitted_development_right_path(planning_application),
            class: "govuk-link"
          )
        )

        expect(html).to include(
          "<strong class=\"govuk-tag govuk-tag--grey app-task-list__task-tag\">Not started</strong>"
        )
      end
    end

    context "when checked" do
      let!(:permitted_development_right) { create(:permitted_development_right, :checked, planning_application: planning_application) }

      it "the task list row shows invalid status html" do
        html = presenter.task_list_row

        expect(html).to include("app-task-list__task-name")

        expect(html).to include(
          link_to(
            "Permitted development rights",
            planning_application_permitted_development_right_path(planning_application, permitted_development_right),
            class: "govuk-link"
          )
        )

        expect(html).to include(
          "<strong class=\"govuk-tag govuk-tag--green app-task-list__task-tag\">Checked</strong>"
        )
      end
    end

    context "when removed" do
      let!(:permitted_development_right) { create(:permitted_development_right, :removed, planning_application: planning_application) }

      it "the task list row shows invalid status html" do
        html = presenter.task_list_row

        expect(html).to include("app-task-list__task-name")

        expect(html).to include(
          link_to(
            "Permitted development rights",
            planning_application_permitted_development_right_path(planning_application, permitted_development_right),
            class: "govuk-link"
          )
        )

        expect(html).to include(
          "<strong class=\"govuk-tag govuk-tag--red app-task-list__task-tag\">Removed</strong>"
        )
      end
    end

    context "when in progress" do
      let!(:permitted_development_right) { create(:permitted_development_right, :in_progress, planning_application: planning_application) }

      it "the task list row shows invalid status html" do
        html = presenter.task_list_row

        expect(html).to include("app-task-list__task-name")

        expect(html).to include(
          link_to(
            "Permitted development rights",
            edit_planning_application_permitted_development_right_path(planning_application, permitted_development_right),
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
