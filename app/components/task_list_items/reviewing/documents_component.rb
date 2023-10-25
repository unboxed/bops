# frozen_string_literal: true

module TaskListItems
  module Reviewing
    class DocumentsComponent < TaskListItems::BaseComponent
      def initialize(planning_application:)
        @planning_application = planning_application
      end

      attr_reader :planning_application

      def link_text
        t(".review_documents_for")
      end

      def link_path
        planning_application_review_documents_path(planning_application)
      end

      def status_tag_component
        StatusTags::BaseComponent.new(
          status: planning_application.review_documents_for_recommendation_status.to_sym
        )
      end
    end
  end
end
