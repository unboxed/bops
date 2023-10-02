# frozen_string_literal: true

module TaskListItems
  class SiteNoticeComponent < TaskListItems::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
    end

    private

    def link_text
      t(".link_text")
    end

    def link_path
      new_planning_application_site_notice_path(@planning_application)
    end

    def status_tag_component
      StatusTags::BaseComponent.new(
        status: @planning_application.site_notices.empty? ? "not_started" : "complete"
      )
    end
  end
end
