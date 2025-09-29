# frozen_string_literal: true

module TaskListItems
  module Assessment
    class AssessmentDetailComponent < TaskListItems::BaseComponent
      include AssessmentDetailable

      OPTIONAL = ["site_description", "summary_of_work"].freeze

      def initialize(planning_application:, category:)
        @planning_application = planning_application
        @category = category
      end

      private

      attr_reader :planning_application, :category

      def link_text
        t(".#{category}")
      end

      def link_path
        case status
        when :not_started, :to_be_reviewed, :optional
          new_planning_application_assessment_assessment_detail_path(
            planning_application,
            category:
          )
        when :in_progress
          edit_planning_application_assessment_assessment_detail_path(
            planning_application,
            assessment_detail,
            category:
          )
        else
          planning_application_assessment_assessment_detail_path(
            planning_application,
            assessment_detail,
            category:
          )
        end
      end

      def status
        if assessment_detail_update_required?(assessment_detail)
          :to_be_reviewed
        elsif not_started? && OPTIONAL.include?(category)
          :optional
        elsif not_started?
          :not_started
        elsif assessment_detail.assessment_in_progress?
          :in_progress
        else
          :complete
        end
      end

      def not_started?
        assessment_detail.blank? || assessment_detail.assessment_not_started?
      end

      def assessment_detail
        @assessment_detail || planning_application.send(category)
      end
    end
  end
end
