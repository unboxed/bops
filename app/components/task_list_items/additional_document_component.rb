# frozen_string_literal: true

module TaskListItems
  class AdditionalDocumentComponent < TaskListItems::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
    end

    private

    attr_reader :planning_application

    def link_text
      t(".check_missing_documents")
    end

    def link_path
      edit_planning_application_validation_documents_path(planning_application)
    end

    def status
      if planning_application.additional_document_validation_requests.open_or_pending.any?
        :invalid
      elsif planning_application.documents_missing == false
        :valid
      else
        :not_started
      end
    end
  end
end
