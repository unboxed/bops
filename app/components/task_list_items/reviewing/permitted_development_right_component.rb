# frozen_string_literal: true

module TaskListItems
  module Reviewing
    class PermittedDevelopmentRightComponent < TaskListItems::BaseComponent
      include Recommendable
      include PermittedDevelopmentRightable

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
        StatusTags::ReviewComponent.new(
          review_item: permitted_development_right, updated:
        )
      end

      def updated
        recommendation_submitted_and_unchallenged? &&
          permitted_development_right_updated?
      end
    end
  end
end
