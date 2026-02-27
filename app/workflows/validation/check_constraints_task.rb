# frozen_string_literal: true

module Validation
  class CheckConstraintsTask < WorkflowTask
    def task_list_link_text
      "Check constraints"
    end

    def task_list_link
      planning_application_validation_constraints_path(planning_application)
    end

    def task_list_status
      planning_application.constraints_checked? ? :complete : :not_started
    end
  end
end
