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
      if @planning_application.site_notices.empty?
        StatusTags::BaseComponent.new(
          status: "not_started"
        )
      else
        StatusTags::BaseComponent.new(
          status: "complete"
        )
      end
    end
  end
end
