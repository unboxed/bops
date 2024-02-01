# frozen_string_literal: true

module TaskListItems
  module Reviewing
    class ConditionComponent < TaskListItems::BaseComponent
      def initialize(condition_set:)
        @condition_set = condition_set
      end

      private

      attr_reader :condition_set
      delegate :planning_application, to: :condition_set

      def link_text
        t(".link_text")
      end

      def link_path
        planning_application_review_conditions_path(planning_application)
      end

      def status_tag_component
        StatusTags::BaseComponent.new(status:)
      end

      def status
        condition_set.review&.status || :not_started
      end

      def link_active?
        planning_application.awaiting_determination? ||
          planning_application.to_be_reviewed?
      end
    end
  end
end
