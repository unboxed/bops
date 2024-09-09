# frozen_string_literal: true

module TaskListItems
  module Assessment
    class PlanningApplicationPolicyClassComponent < TaskListItems::BaseComponent
      def initialize(planning_application_policy_class:, planning_application:)
        @planning_application = planning_application
        @policy_class = planning_application_policy_class.new_policy_class
        @part = @policy_class.policy_part
      end

      private

      attr_reader :policy_class, :planning_application

      def link_text
        "Part #{@part.number}, Class #{@policy_class.section}"
      end

      def link_path
        "#"
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
