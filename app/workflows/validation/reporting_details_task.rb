# frozen_string_literal: true

module Validation
  class ReportingDetailsTask < WorkflowTask
    def task_list_link_text
      "Add reporting details"
    end

    def task_list_link
      if planning_application.reporting_type_code.present?
        planning_application_validation_reporting_type_path(planning_application)
      else
        edit_planning_application_validation_reporting_type_path(planning_application)
      end
    end

    def task_list_status
      planning_application.reporting_type_status
    end
  end
end
