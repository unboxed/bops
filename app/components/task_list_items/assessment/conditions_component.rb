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
        pre_commencement? ? "Add pre-commencement conditions" : "Add conditions"
      end

      def link_path
        if pre_commencement?
          planning_application_assessment_conditions_path(planning_application_id, pre_commencement: true)
        else
          planning_application_assessment_conditions_path(planning_application_id)
        end
      end

      def pre_commencement?
        condition_set.pre_commencement?
      end

      def status_tag_component
        StatusTags::BaseComponent.new(status:)
      end

      def status
        if condition_set.current_review.present?
          if condition_set.pre_commencement?
            if condition_set.validation_requests.any? { |validation_request| !validation_request.approved.nil? } && !condition_set.current_review.complete?
              "updated"
            else
              condition_set.current_review.status.to_sym
            end
          else
            condition_set.current_review.status.to_sym
          end
        else
          :not_started
        end
      end
    end
  end
end
