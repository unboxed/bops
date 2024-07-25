# frozen_string_literal: true

module TaskListItems
  module Reviewing
    class ConsiderationsComponent < TaskListItems::BaseComponent
      def initialize(planning_application:)
        @planning_application = planning_application
      end

      private

      attr_reader :planning_application
      delegate :consideration_set, to: :planning_application
      delegate :current_review, to: :consideration_set

      def link_text
        t(".link_text")
      end

      def link_path
        planning_application_review_considerations_path(planning_application)
      end

      def status_tag_component
        StatusTags::ReviewComponent.new(
          review_item: current_review,
          updated: current_review.updated?
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
