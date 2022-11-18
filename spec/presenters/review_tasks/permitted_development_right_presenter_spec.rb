# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReviewTasks::PermittedDevelopmentRightPresenter, type: :presenter do
  include ActionView::TestCase::Behavior

  subject(:presenter) { described_class.new(view, planning_application) }

  let(:context) { ActionView::Base.new }
  let!(:planning_application) { create(:planning_application, :in_assessment) }
  let!(:permitted_development_right) { create(:permitted_development_right, planning_application: planning_application) }

  describe "#task_list_row" do
    context "when not started" do
      it "the task list row shows the not started status html" do
        html = presenter.task_list_row

        expect(html).to include("app-task-list__task-name")

        expect(html).to include(
          link_to(
            "Permitted development rights",
            edit_planning_application_review_permitted_development_right_path(planning_application, permitted_development_right),
            class: "govuk-link"
          )
        )

        expect(html).to include(
          "<strong class=\"govuk-tag govuk-tag--grey app-task-list__task-tag\">Not started</strong>"
        )
      end
    end

    context "when in progress" do
      let!(:permitted_development_right) { create(:permitted_development_right, review_status: "review_in_progress", planning_application: planning_application) }

      it "the task list row shows the in progress status html" do
        html = presenter.task_list_row

        expect(html).to include("app-task-list__task-name")

        expect(html).to include(
          link_to(
            "Permitted development rights",
            planning_application_review_permitted_development_right_path(planning_application, permitted_development_right),
            class: "govuk-link"
          )
        )

        expect(html).to include(
          "<strong class=\"govuk-tag app-task-list__task-tag\">In progress</strong>"
        )
      end
    end

    context "when complete" do
      let!(:permitted_development_right) { create(:permitted_development_right, review_status: "review_complete", planning_application: planning_application) }

      it "the task list row shows the complete status html" do
        html = presenter.task_list_row

        expect(html).to include("app-task-list__task-name")

        expect(html).to include(
          link_to(
            "Permitted development rights",
            planning_application_review_permitted_development_right_path(planning_application, permitted_development_right),
            class: "govuk-link"
          )
        )

        expect(html).to include(
          "<strong class=\"govuk-tag govuk-tag--blue app-task-list__task-tag\">Complete</strong>"
        )
      end
    end
  end
end
