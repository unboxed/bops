# frozen_string_literal: true

module Validation
  class CheckLegislationDescriptionTask < WorkflowTask
    def task_list_link_text
      if planning_application.validated?
        "Planning application has already been validated"
      else
        I18n.t("task_list_items.validating.legislation_component.check_legislation")
      end
    end

    def task_list_link
      return if planning_application.validated?

      planning_application_validation_legislation_path(planning_application)
    end

    def task_list_status
      planning_application.legislation_checked? ? :complete : :not_started
    end

    def render?
      planning_application.application_type.legislation_description
    end
  end
end
