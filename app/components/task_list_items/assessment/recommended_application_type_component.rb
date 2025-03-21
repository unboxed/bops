# frozen_string_literal: true

module TaskListItems
  module Assessment
    class RecommendedApplicationTypeComponent < TaskListItems::BaseComponent
      def initialize(planning_application:)
        @planning_application = planning_application
      end

      private

      attr_reader :planning_application

      def link_text
        "Choose application type"
      end

      def link_path
        if planning_application.recommended_application_type.present?
          planning_application_assessment_recommended_application_type_path(planning_application)
        else
          edit_planning_application_assessment_recommended_application_type_path(planning_application)
        end
      end

      def status
        planning_application.recommended_application_type.blank? ? :not_started : :complete
      end
    end
  end
end
