# frozen_string_literal: true

module TaskListItems
  module Assessment
    class SiteHistoryComponent < TaskListItems::BaseComponent
      def initialize(planning_application:)
        @planning_application = planning_application
      end

      private

      attr_reader :planning_application

      def link_text
        "Check site history"
      end

      def link_path
        planning_application_assessment_site_histories_path(planning_application)
      end

      def status_tag_component
        StatusTags::BaseComponent.new(status:)
      end

      def status
        planning_application.site_history_checked ? :complete : :optional
      end
    end
  end
end
