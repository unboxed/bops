# frozen_string_literal: true

require "rails_helper"

RSpec.describe ValidationTasks::ReviewPresenter, type: :presenter do
  include ActionView::TestCase::Behavior

  subject(:presenter) { described_class.new(view, planning_application) }

  let(:context) { ActionView::Base.new }

  describe "#task_list_row" do
    context "when planning application is not started" do
      let(:planning_application) { create(:planning_application, :not_started) }

      it "the task list row shows invalid status html" do
        html = presenter.task_list_row

        expect(html).to include("app-task-list__task-name")
        expect(html).to include("Send validation decision")
        expect(html).to include(
          "/planning_applications/#{planning_application.id}/validation_decision"
        )
        expect(html).to include(
          "<strong class=\"govuk-tag govuk-tag--grey app-task-list__task-tag\">Not started</strong>"
        )
      end
    end

    context "when planning application is invalidated" do
      let(:planning_application) { create(:planning_application, :invalidated) }

      it "the task list row shows an updated status html" do
        html = presenter.task_list_row

        expect(html).to include("app-task-list__task-name")
        expect(html).to include("Send validation decision")
        expect(html).to include(
          "/planning_applications/#{planning_application.id}/validation_decision"
        )
        expect(html).to include(
          "<strong class=\"govuk-tag govuk-tag--red app-task-list__task-tag\">Invalid</strong>"
        )
      end
    end

    context "when planning application is valid" do
      let(:planning_application) { create(:planning_application, :in_assessment) }

      it "the task list row shows an updated status html" do
        html = presenter.task_list_row

        expect(html).to include("app-task-list__task-name")
        expect(html).to include("Send validation decision")
        expect(html).to include(
          "/planning_applications/#{planning_application.id}/validation_decision"
        )
        expect(html).to include(
          "<strong class=\"govuk-tag govuk-tag--green app-task-list__task-tag\">Valid</strong>"
        )
      end
    end
  end
end
