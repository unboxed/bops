# frozen_string_literal: true

module Validation
  class CheckMissingDocumentsTask < WorkflowTask
    def task_list_link_text
      if planning_application.validated?
        "Planning application has already been validated"
      else
        I18n.t("task_list_items.additional_document_component.check_missing_documents")
      end
    end

    def task_list_link
      edit_planning_application_validation_documents_path(planning_application) unless planning_application.validated?
    end

    def task_list_status
      if planning_application.additional_document_validation_requests.open_or_pending.any?
        :awaiting_response
      elsif planning_application.documents_missing == false
        :complete
      else
        :not_started
      end
    end
  end
end
