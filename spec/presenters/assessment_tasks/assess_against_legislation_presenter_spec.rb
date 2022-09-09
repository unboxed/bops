# frozen_string_literal: true

require "rails_helper"

RSpec.describe AssessmentTasks::AssessAgainstLegislationPresenter, type: :presenter do
  include ActionView::TestCase::Behavior

  subject(:presenter) { described_class.new(view, planning_application, policy_class) }

  let(:context) { ActionView::Base.new }
  let!(:planning_application) { create(:planning_application, :in_assessment) }

  describe "#task_list_row" do
    context "when policy class status is 'complete'" do
      let(:policy_class) { create(:policy_class, :complete) }

      it "the task list row shows invalid status html" do
        html = presenter.task_list_row

        expect(html).to include("app-task-list__task-name")

        expect(html).to include(
          link_to(
            policy_class,
            planning_application_policy_class_path(planning_application, policy_class),
            class: "govuk-link"
          )
        )

        expect(html).to include(
          "<strong class=\"govuk-tag app-task-list__task-tag govuk-tag--blue\">Complete</strong>"
        )
      end
    end

    context "when policy class status is 'in_assessment'" do
      let(:policy_class) { create(:policy_class, :in_assessment) }

      it "the task list row shows invalid status html" do
        html = presenter.task_list_row

        expect(html).to include("app-task-list__task-name")

        expect(html).to include(
          link_to(
            policy_class,
            edit_planning_application_policy_class_path(planning_application, policy_class),
            class: "govuk-link"
          )
        )

        expect(html).to include(
          "<strong class=\"govuk-tag app-task-list__task-tag \">In assessment</strong>"
        )
      end
    end
  end
end
