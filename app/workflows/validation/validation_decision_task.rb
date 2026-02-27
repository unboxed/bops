# frozen_string_literal: true

module Validation
  class ValidationDecisionTask < WorkflowTask
    def task_list_link_text
      I18n.t("task_list_items.validation_decision_component.send_validation_decision")
    end

    def task_list_link
      validation_decision_planning_application_path(planning_application)
    end

    def task_list_status
      if planning_application.validated?
        :valid
      elsif planning_application.invalidated?
        :invalid
      else
        :not_started
      end
    end
  end
end
