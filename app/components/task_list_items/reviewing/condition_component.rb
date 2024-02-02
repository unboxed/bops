# frozen_string_literal: true

module TaskListItems
  module Reviewing
    class ConditionComponent < TaskListItems::BaseComponent
      include Recommendable

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
        if condition_set.current_review&.status == "to_be_reviewed" || condition_set.current_review&.status == "updated"
          condition_set.current_review.status
        else
          condition_set.current_review&.review_status
        end
      end

      def link_active?
        planning_application.awaiting_determination? ||
          planning_application.to_be_reviewed?
      end
    end
  end
end
