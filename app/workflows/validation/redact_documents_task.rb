# frozen_string_literal: true

module Validation
  class RedactDocumentsTask < WorkflowTask
    def task_list_link_text
      I18n.t("task_list_items.redact_documents_component.redact_documents")
    end

    def task_list_link
      planning_application_validation_documents_redactions_path(planning_application)
    end

    def task_list_status
      planning_application.documents_status.to_sym
    end
  end
end
