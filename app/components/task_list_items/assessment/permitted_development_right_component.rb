# frozen_string_literal: true

module TaskListItems
  module Assessment
    class PermittedDevelopmentRightComponent < TaskListItems::BaseComponent
      def initialize(planning_application:)
        @planning_application = planning_application
      end

      private

      attr_reader :planning_application

      delegate(:permitted_development_right, to: :planning_application)

      def link_text
        t(".permitted_development_rights")
      end

      def link_path
        case status
        when :not_started, :to_be_reviewed
          new_planning_application_assessment_permitted_development_right_path(
            planning_application
          )
        when :in_progress
          edit_planning_application_assessment_permitted_development_right_path(
            planning_application,
            permitted_development_right
          )
        when :complete, :removed
          planning_application_assessment_permitted_development_right_path(
            planning_application,
            permitted_development_right
          )
        end
      end

      def status
        if permitted_development_right.blank?
          :not_started
        elsif to_be_reviewed?
          :to_be_reviewed
        elsif permitted_development_right.status.to_sym == :checked
          :complete
        else
          permitted_development_right.status.to_sym
        end
      end

      def to_be_reviewed?
        planning_application.recommendation&.rejected? &&
          permitted_development_right.update_required?
      end
    end
  end
end
