# frozen_string_literal: true

module TaskListItems
  class DocumentComponent < TaskListItems::BaseComponent
    def initialize(planning_application:, document:)
      @planning_application = planning_application
      @document = document
    end

    private

    attr_reader :planning_application, :document

    def replacement_document_validation_request
      document.validation_request
    end

    def link_text
      t(".check_document", document: truncated_document_name)
    end

    def truncated_document_name
      truncate(document_name.to_s, length: 25)
    end

    def document_name
      document.numbers.presence || document.name
    end

    def link_path
      if status == :invalid
        planning_application_validation_validation_request_path(
          planning_application,
          replacement_document_validation_request,
          request_type: "replacement_document"
        )
      else
        edit_planning_application_document_path(
          planning_application,
          document,
          validate: :yes
        )
      end
    end

    def status
      @status ||= if document.validated?
        :valid
      elsif replacement_document_validation_request&.open_or_pending?
        :invalid
      elsif ValidationRequest.find_by(old_document: document).present?
        :updated
      else
        :not_started
      end
    end
  end
end
