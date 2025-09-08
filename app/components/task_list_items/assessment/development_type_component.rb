# frozen_string_literal: true

module TaskListItems
  module Assessment
    class DevelopmentTypeComponent < TaskListItems::BaseComponent
      def initialize(planning_application:)
        @planning_application = planning_application
      end

      private

      def link_text
        "Check if the proposal is development"
      end

      def link_path
        edit_planning_application_assessment_development_type_path(@planning_application)
      end

      def status_tag_component
        StatusTags::BaseComponent.new(status:)
      end

      def status
        if @planning_application.section_55_development.nil?
          :not_started
        else
          :complete
        end
      end
    end
  end
end
