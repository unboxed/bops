# frozen_string_literal: true

module TaskListItems
  class SiteVisitComponent < TaskListItems::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
      @consultation = planning_application.consultation
    end

    private

    attr_reader :consultation

    delegate(:site_visit, to: :consultation)

    def link_text
      "Site visit"
    end

    def link_path
      if @consultation.site_visits.any?
        planning_application_publicity_site_visits_path(@planning_application, @consultation)
      else
        new_planning_application_publicity_site_visit_path(@planning_application, @consultation)
      end
    end

    def status_tag_component
      StatusTags::BaseComponent.new(
        status: @consultation.site_visit&.status || "not_started"
      )
    end
  end
end
