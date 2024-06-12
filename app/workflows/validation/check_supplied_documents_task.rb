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
      if planning_application.all_null_documents? == true
        :not_started
      elsif planning_application.all_valid_documents? == true
        :complete
      else
        :in_progress
      end
    end
  end
end
