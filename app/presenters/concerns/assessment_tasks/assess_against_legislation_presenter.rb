# frozen_string_literal: true

module AssessmentTasks
  extend ActiveSupport::Concern

  class AssessAgainstLegislationPresenter < PlanningApplicationPresenter
    include PolicyReferencesHelper

    attr_reader :policy_class

    def initialize(template, planning_application, policy_class)
      super(template, planning_application)

      @policy_class = PolicyClassPresenter.new(policy_class)
    end

    def task_list_row
      html = tag.span class: "app-task-list__task-name" do
        concat policy_class_link
      end

      html.concat policy_class_tag
    end

    private

    def policy_class_link
      link_to(
        policy_class_title,
        policy_class.default_path,
        class: "govuk-link"
      )
    end

    def policy_class_tag
      tag.strong(
        I18n.t("policy_classes.#{policy_class.status}"),
        class: "govuk-tag app-task-list__task-tag #{'govuk-tag--blue' if policy_class.complete?}"
      )
    end

    def policy_class_title
      I18n.t(
        "policy_classes.title",
        part: policy_class.part,
        class: policy_class.section
      )
    end
  end
end
