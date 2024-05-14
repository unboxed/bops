# frozen_string_literal: true

module Validation
  class ReviewValidationRequestsTask < WorkflowTask
    def task_list_link_text
      "Review validation requests"
    end

    def task_list_link
      planning_application_validation_validation_requests_path(planning_application)
    end
  end
end
