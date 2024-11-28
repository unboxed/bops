# frozen_string_literal: true

module TaskListItems
  module Assessment
    class PermittedDevelopmentRightComponent < TaskListItems::BaseComponent
      def initialize(planning_application:)
        @planning_application = planning_application
      end

      private

      attr_reader :planning_application

      delegate :permitted_development_right, to: :planning_application
      delegate :complete?, :removed?, :updated?, to: :permitted_development_right

      def link_text
        t(".permitted_development_rights")
      end

      def link_path
        if complete? || updated?
          planning_application_assessment_permitted_development_rights_path(planning_application)
        else
          edit_planning_application_assessment_permitted_development_rights_path(planning_application)
        end
      end

      def status
        if complete? && removed?
          :removed
        else
          permitted_development_right.status.to_sym
        end
      end
    end
  end
end
