# frozen_string_literal: true

module Validation
  class CheckSuppliedDocumentsTask < WorkflowTask
    def task_list_link_text
      if planning_application.validated?
        "Planning application has already been validated"
      else
        "Tag and validate supplied documents"
      end
    end

    def task_list_link
      supply_documents_planning_application_path(@planning_application) unless planning_application.validated?
    end

    def task_list_status
    end
  end
end
