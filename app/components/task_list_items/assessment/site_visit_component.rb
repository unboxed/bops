# frozen_string_literal: true

module TaskListItems
  module Assessment
    class SiteVisitComponent < TaskListItems::BaseComponent
      def initialize(planning_application:)
        @planning_application = planning_application
      end

      private

      attr_reader :planning_application

      delegate :site_visit, to: :planning_application

      def link_text
        "Site visit"
      end

      def link_path
        if planning_application.site_visits.any?
          planning_application_assessment_site_visits_path(@planning_application)
        else
          new_planning_application_assessment_site_visit_path(@planning_application)
        end
      end

      def status_tag_component
        StatusTags::BaseComponent.new(
          status: site_visit&.status || "not_started"
        )
      end
    end
  end
end
