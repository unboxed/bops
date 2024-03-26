# frozen_string_literal: true

module TaskListItems
  module Assessment
    class ConsulteesConsultedComponent < TaskListItems::BaseComponent
      def initialize(planning_application:)
        @planning_application = planning_application
      end

      private

      attr_reader :planning_application

      def link_text
        "Check consultees consulted"
      end

      def link_path
        planning_application_assessment_consultees_path(planning_application)
      end

      def status
        if @planning_application.consultation&.consultees_checked?
          :complete
        else
          :not_started
        end
      end

      def status_tag_component
        StatusTags::BaseComponent.new(status:)
      end
    end
  end
end
