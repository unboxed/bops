# frozen_string_literal: true

module TaskListItems
  module Review
    class AssessmentDetailsComponent < TaskListItems::BaseComponent
      include AssessmentDetailable

      def initialize(planning_application:)
        @planning_application = planning_application
      end

      private

      attr_reader :planning_application, :category

      def link_text
        t(".review_assessment_summaries")
      end

      def link_path
        if review_assessment_details_complete?
          planning_application_review_assessment_details_path(
            planning_application
          )
        else
          edit_planning_application_review_assessment_details_path(
            planning_application
          )
        end
      end

      def status_tag_component
        StatusTags::Review::AssessmentDetailsComponent.new(
          planning_application:
        )
      end

      def link_active?
        planning_application.awaiting_determination? ||
          planning_application.to_be_reviewed?
      end
    end
  end
end
