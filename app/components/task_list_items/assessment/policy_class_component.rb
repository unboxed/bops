# frozen_string_literal: true

module TaskListItems
  module Assessment
    class PolicyClassComponent < TaskListItems::BaseComponent
      def initialize(policy_class:, planning_application:)
        @planning_application = planning_application
        @policy_class = PolicyClassPresenter.new(policy_class)
      end

      private

      attr_reader :policy_class, :planning_application

      def link_text
        I18n.t(
          "planning_applications.assessment.policy_classes.title",
          part: policy_class.part,
          class: policy_class.section
        )
      end

      def link_path
        policy_class.default_path
      end

      def status_tag_component
        StatusTags::PolicyClassComponent.new(
          policy_class:,
          planning_application:
        )
      end
    end
  end
end
