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
        StatusTags::BaseComponent.new(status:)
      end

      def status
        if to_be_reviewed?
          :to_be_reviewed
        elsif policy_class&.current_review&.status == "in_progress" || policy_class.current_review.nil?
          :in_progress
        elsif policy_class&.current_review&.status == "complete" || policy_class.current_review&.status == "updated"
          :complete
        end
      end

      def to_be_reviewed?
        planning_application.recommendation&.rejected? &&
          policy_class.update_required?
      end
    end
  end
end
