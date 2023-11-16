# frozen_string_literal: true

module TaskListItems
  class RedactDocumentsComponent < TaskListItems::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
    end

    private

    attr_reader :planning_application

    def link_text
      t(".redact_documents")
    end

    def link_path
      planning_application_validation_documents_redactions_path(planning_application)
    end

    def status_tag_component
      StatusTags::RedactDocumentsComponent.new(
        planning_application:
      )
    end
  end
end
