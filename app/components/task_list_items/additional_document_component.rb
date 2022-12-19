# frozen_string_literal: true

module TaskListItems
  class AdditionalDocumentComponent < TaskListItems::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
    end

    private

    attr_reader :planning_application

    def link_text
      t(".check_required_documents")
    end

    def link_path
      validation_documents_planning_application_path(planning_application)
    end

    def status_tag_component
      StatusTags::AdditionalDocumentComponent.new(
        planning_application: planning_application
      )
    end
  end
end
