# frozen_string_literal: true

module TaskListItems
  module Reviewing
    class ConditionsComponent < TaskListItems::BaseComponent
      def initialize(condition_set:)
        @condition_set = condition_set
      end

      private

      attr_reader :condition_set
      delegate :planning_application, to: :condition_set

      def link_text
        if @condition_set.pre_commencement?
          t(".pre_commencement.link_text")
        else
          t(".link_text")
        end
      end

      def link_path
        if @condition_set.pre_commencement?
          planning_application_review_pre_commencement_conditions_path(planning_application)
        else
          planning_application_review_conditions_path(planning_application)
        end
      end

      def status_tag_component
        StatusTags::ReviewComponent.new(
          review_item: condition_set.current_review,
          updated: condition_set.current_review&.status == "updated"
        )
      end

      def link_active?
        planning_application.awaiting_determination? ||
          planning_application.to_be_reviewed? ||
          planning_application.in_committee?
      end
    end
  end
end
