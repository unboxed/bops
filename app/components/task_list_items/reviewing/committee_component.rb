# frozen_string_literal: true

module TaskListItems
  module Reviewing
    class CommitteeComponent < TaskListItems::BaseComponent
      def initialize(planning_application:)
        @planning_application = planning_application
      end

      private

      attr_reader :planning_application

      delegate(:committee_decision, to: :planning_application)

      def link_text
        t(".link_text")
      end

      def link_path
        if committee_decision.current_review.review_complete?
          planning_application_review_committee_decision_path(planning_application, planning_application.committee_decision)
        else
          edit_planning_application_review_committee_decision_path(planning_application, planning_application.committee_decision)
        end
      end

      def status_tag_component
        StatusTags::ReviewComponent.new(review_item: committee_decision.current_review)
      end
    end
  end
end
