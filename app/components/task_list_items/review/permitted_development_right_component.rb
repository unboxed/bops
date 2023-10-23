# frozen_string_literal: true

module TaskListItems
  module Review
    class PermittedDevelopmentRightComponent < TaskListItems::BaseComponent
      def initialize(planning_application:)
        @planning_application = planning_application
      end

      private

      attr_reader :planning_application

      delegate(:permitted_development_right, to: :planning_application)

      def link_text
        t(".review_permitted_development_rights")
      end

      def link_path
        if permitted_development_right.review_complete?
          planning_application_review_permitted_development_right_path(
            planning_application,
            permitted_development_right
          )
        else
          edit_planning_application_review_permitted_development_right_path(
            planning_application,
            permitted_development_right
          )
        end
      end

      def status_tag_component
        StatusTags::Review::PermittedDevelopmentRightComponent.new(
          planning_application:,
          permitted_development_right:
        )
      end
    end
  end
end
