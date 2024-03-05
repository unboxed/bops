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
        if @planning_application.informative_set.current_review
          @planning_application.informative_set.current_review.status.to_sym
        else
          :not_started
        end
      end
    end
  end
end
