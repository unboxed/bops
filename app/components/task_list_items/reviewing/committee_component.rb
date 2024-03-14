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
        "Notify neighbours of committee meeting"
      end

      def link_path
        edit_planning_application_review_committee_decision_path(planning_application, planning_application.committee_decision)
      end

      def status_tag_component
        StatusTags::BaseComponent.new(status:)
      end

      def status
        :not_started
      end
    end
  end
end
