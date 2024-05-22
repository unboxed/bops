# frozen_string_literal: true

module TaskListItems
  module Reviewing
    class InformativesComponent < TaskListItems::BaseComponent
      def initialize(informative_set:)
        @informative_set = informative_set
      end

      private

      attr_reader :informative_set
      delegate :planning_application, to: :informative_set

      def link_text
        t(".link_text")
      end

      def link_path
        planning_application_review_informatives_path(planning_application)
      end

      def status_tag_component
        StatusTags::ReviewComponent.new(
          review_item: informative_set.current_review,
          updated: informative_set.current_review&.status == "updated"
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
