# frozen_string_literal: true

require "rails_helper"

RSpec.describe AssessmentTasks::AssessAgainstLegislationPresenter, type: :presenter do
  include ActionView::TestCase::Behavior

  subject(:presenter) { described_class.new(view, planning_application, policy_class) }

  let(:context) { ActionView::Base.new }
  let!(:planning_application) { create(:planning_application, :in_assessment) }

  describe "#task_list_row" do
    context "when policy class complies" do
      let(:policy_class) { build(:policy_class) }

      before { planning_application.policy_classes += [policy_class] }

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
          "<strong class=\"govuk-tag app-task-list__task-tag govuk-tag--green\">complies</strong>"
        )
      end
    end

    context "when policy class does not comply" do
      let(:policy_class) do
        build(:policy_class, policies: [policy])
      end

      let(:policy) { build(:policy, :does_not_comply) }

      before { planning_application.policy_classes += [policy_class] }

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
          "<strong class=\"govuk-tag app-task-list__task-tag govuk-tag--red\">does not comply</strong>"
        )
      end
    end

    context "when policy class is in assessment" do
      let(:policy_class) do
        build(:policy_class, policies: [policy])
      end

      let(:policy) { build(:policy, :to_be_determined) }

      before { planning_application.policy_classes += [policy_class] }

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
          "<strong class=\"govuk-tag app-task-list__task-tag\">in assessment</strong>"
        )
      end
    end
  end
end
