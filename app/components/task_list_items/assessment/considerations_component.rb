# frozen_string_literal: true

module TaskListItems
  module Assessment
    class ConsiderationsComponent < TaskListItems::BaseComponent
      def initialize(planning_application:)
        @planning_application = planning_application
      end

      private

      attr_reader :planning_application
      delegate :consideration_set, to: :planning_application
      delegate :current_review, to: :consideration_set
      delegate :status, to: :current_review

      def link_text
        t(".link_text")
      end

      def link_path
        planning_application_assessment_considerations_path(planning_application)
      end

      def status_tag_component
        StatusTags::BaseComponent.new(status:)
      end
    end
  end
end
