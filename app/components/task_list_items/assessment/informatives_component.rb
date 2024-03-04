# frozen_string_literal: true

module TaskListItems
  module Assessment
    class InformativesComponent < TaskListItems::BaseComponent
      def initialize(planning_application:)
        @planning_application = planning_application
      end

      private

      def link_text
        "Add informatives"
      end

      def link_path
        planning_application_assessment_informatives_path(@planning_application)
      end

      def status_tag_component
        StatusTags::BaseComponent.new(status:)
      end

      def status
        :not_started
      end
    end
  end
end
