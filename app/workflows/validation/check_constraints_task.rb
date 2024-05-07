# frozen_string_literal: true

module Validation
  class CheckConstraintsTask < WorkflowTask
    def task_list_link_text
      "Check constraints"
    end

    def task_list_link
      planning_application_validation_constraints_path(planning_application)
    end
  end
end
