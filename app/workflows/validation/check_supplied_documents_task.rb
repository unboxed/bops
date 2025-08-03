# frozen_string_literal: true

module Validation
  class CheckSuppliedDocumentsTask < WorkflowTask
    def task_list_link_text
      "Review documents"
    end

    def task_list_link
      supply_documents_planning_application_path(@planning_application) unless planning_application.validated?
    end

    def task_list_status
      checked_count = planning_application.documents.where(checked: true).count
      total_count = planning_application.documents.count

      if checked_count.zero?
        :not_started
      elsif checked_count < total_count
        :in_progress
      else
        :complete
      end
    end
  end
end
