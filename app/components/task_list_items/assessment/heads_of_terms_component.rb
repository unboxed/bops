# frozen_string_literal: true

module TaskListItems
  module Assessment
    class HeadsOfTermsComponent < TaskListItems::BaseComponent
      def initialize(planning_application:)
        @planning_application = planning_application
      end

      private

      attr_reader :planning_application

      def link_text
        "Suggest heads of terms"
      end

      def link_path
        planning_application_assessment_terms_path(@planning_application)
      end

      def status_tag_component
        StatusTags::HeadsOfTermsComponent.new(heads_of_term: planning_application.heads_of_term)
      end
    end
  end
end
