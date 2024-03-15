# frozen_string_literal: true

module TaskListItems
  module Reviewing
    class NotifyCommitteeComponent < TaskListItems::BaseComponent
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
        if planning_application.in_committee?
          planning_application_review_committee_decision_notifications_path(planning_application, planning_application.committee_decision)
        else
          edit_planning_application_review_committee_decision_notifications_path(planning_application, planning_application.committee_decision)
        end
      end

      def status_tag_component
        StatusTags::BaseComponent.new(status:)
      end

      def status
        if planning_application.in_committee_at.present?
          :complete
        else
          :not_started
        end
      end
    end
  end
end
