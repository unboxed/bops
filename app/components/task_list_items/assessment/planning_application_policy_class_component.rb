# frozen_string_literal: true

module TaskListItems
  module Assessment
    class PlanningApplicationPolicyClassComponent < TaskListItems::BaseComponent
      def initialize(planning_application_policy_class:, planning_application:)
        @planning_application = planning_application
        @planning_application_policy_class = planning_application_policy_class
        @policy_class = planning_application_policy_class.policy_class
        @part = @policy_class.policy_part
      end

      private

      attr_reader :policy_class, :planning_application, :part, :planning_application_policy_class

      def link_text
        "Part #{part.number}, Class #{policy_class.section}"
      end

      def link_path
        edit_planning_application_assessment_policy_areas_policy_class_path(
          planning_application, planning_application_policy_class
        )
      end

      def status_tag_component
        StatusTags::BaseComponent.new(status:)
      end

      def status
        :in_progress
      end
    end
  end
end
