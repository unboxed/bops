# frozen_string_literal: true

module AssessmentTasks
  extend ActiveSupport::Concern

  class AssessAgainstLegislationPresenter < PlanningApplicationPresenter
    include PolicyReferencesHelper

    attr_reader :policy_class

    def initialize(template, planning_application, policy_class)
      super(template, planning_application)

      @policy_class = policy_class
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
        policy_class,
        planning_application_policy_class_path(planning_application, policy_class),
        class: "govuk-link"
      )
    end

    def policy_class_tag
      tag.strong policy_class.status, class: class_for_policy_class_status(policy_class.status)
    end
  end
end
