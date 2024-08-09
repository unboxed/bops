# frozen_string_literal: true

module Validation
  class AddValidationRequestTask < WorkflowTask
    def task_list_link_text
      "Add another validation request"
    end

    def task_list_link
      new_planning_application_validation_validation_request_path(planning_application.reference, type: :other_change)
    end
  end
end
