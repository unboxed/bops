# frozen_string_literal: true

require "rails_helper"

RSpec.describe AssessmentTasks::ReviewDocumentsPresenter, type: :presenter do
  include ActionView::TestCase::Behavior

  subject(:presenter) { described_class.new(view, planning_application) }

  let(:context) { ActionView::Base.new }
  let!(:planning_application) { create(:planning_application, :in_assessment) }

  describe "#task_list_row" do
    context "when not started" do
      it "the task list row shows not started status html" do
        html = presenter.task_list_row

        expect(html).to include("app-task-list__task-name")

        expect(html).to include(
          link_to(
            "Review documents for recommendation",
            planning_application_review_documents_path(planning_application),
            class: "govuk-link"
          )
        )

        expect(html).to include(
          "<strong class=\"govuk-tag govuk-tag--grey app-task-list__task-tag\">Not started</strong>"
        )
      end
    end

    context "when in progress" do
      let!(:planning_application) { create(:planning_application, :in_assessment, review_documents_for_recommendation_status: "in_progress") }

      it "the task list row shows in progress status html" do
        html = presenter.task_list_row

        expect(html).to include("app-task-list__task-name")

        expect(html).to include(
          link_to(
            "Review documents for recommendation",
            planning_application_review_documents_path(planning_application),
            class: "govuk-link"
          )
        )

        expect(html).to include(
          "<strong class=\"govuk-tag app-task-list__task-tag\">In progress</strong>"
        )
      end
    end

    context "when complete" do
      let!(:planning_application) { create(:planning_application, :in_assessment, review_documents_for_recommendation_status: "complete") }

      it "the task list row shows the complete status html" do
        html = presenter.task_list_row

        expect(html).to include("app-task-list__task-name")

        expect(html).to include(
          link_to(
            "Review documents for recommendation",
            planning_application_review_documents_path(planning_application),
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
