# frozen_string_literal: true

module TaskListItems
  module Assessment
    class ConditionsComponent < TaskListItems::BaseComponent
      def initialize(condition_set:)
        @condition_set = condition_set
      end

      private

      attr_reader :condition_set
      delegate :planning_application_id, to: :condition_set

      def link_text
        "Add conditions"
      end

      def link_path
        planning_application_assessment_conditions_path(planning_application_id)
      end

      def status_tag_component
        StatusTags::BaseComponent.new(status:)
      end

      def status
        if condition_set.current_review.present?
          condition_set.current_review.status.to_sym
        else
          :not_started
        end
      end
    end
  end
end
