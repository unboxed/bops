# frozen_string_literal: true

module TaskListItems
  module Assessment
    class MeetingComponent < TaskListItems::BaseComponent
      def initialize(planning_application:)
        @planning_application = planning_application
      end

      private

      attr_reader :planning_application

      delegate :meeting, to: :planning_application

      def link_text
        "Meeting"
      end

      def link_path
        planning_application_assessment_meetings_path(@planning_application)
      end

      def status_tag_component
        StatusTags::BaseComponent.new(
          status: @planning_application.meetings.any? ? @planning_application.meetings.last.status : "not_started"
        )
      end
    end
  end
end
