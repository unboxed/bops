# frozen_string_literal: true

require "rails_helper"

RSpec.describe AssessmentTasks::AssessAgainstLegislationPresenter, type: :presenter do
  include ActionView::TestCase::Behavior

  subject(:presenter) { described_class.new(view, planning_application, policy_class) }

  let(:context) { ActionView::Base.new }
  let!(:planning_application) { create(:planning_application, :in_assessment) }

  describe "#task_list_row" do
    context "when policy class status is 'complete'" do
      let(:policy_class) do
        create(
          :policy_class,
          :complete,
          planning_application: planning_application
        )
      end

      it "the task list row shows invalid status html" do
        html = presenter.task_list_row

        expect(html).to include("app-task-list__task-name")

        expect(html).to include(
          "<a class=\"govuk-link\" href=\"/planning_applications/#{planning_application.id}/policy_classes/#{policy_class.id}\">Part 1, Class #{policy_class.section}</a>"
        )

        expect(html).to include(
          "<strong class=\"govuk-tag app-task-list__task-tag govuk-tag--blue\">Complete</strong>"
        )
      end
    end

    context "when policy class status is 'in_assessment'" do
      let(:policy_class) do
        create(
          :policy_class,
          :in_assessment,
          planning_application: planning_application
        )
      end

      it "the task list row shows invalid status html" do
        html = presenter.task_list_row

        expect(html).to include("app-task-list__task-name")

        expect(html).to include(
          "<a class=\"govuk-link\" href=\"/planning_applications/#{planning_application.id}/policy_classes/#{policy_class.id}/edit\">Part 1, Class #{policy_class.section}</a>"
        )

        expect(html).to include(
          "<strong class=\"govuk-tag app-task-list__task-tag \">In assessment</strong>"
        )
      end
    end
  end
end
