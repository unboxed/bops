# frozen_string_literal: true

module Validation
  class CheckSuppliedDocumentsTask < WorkflowTask
    def task_list_link_text
      "Review documents"
    end

    def task_list_link
      supply_documents_planning_application_path(@planning_application)
    end

    def task_list_status
      documents = planning_application.documents.active
      checked_count = documents.where(checked: true).count
      total_count = documents.count

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
