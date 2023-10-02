# frozen_string_literal: true

module TaskListItems
  class ConfirmSiteNoticeComponent < TaskListItems::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
      @site_notice = @planning_application.site_notices&.last
    end

    private

    attr_reader :planning_application, :site_notice

    def link_text
      t(".link_text")
    end

    def link_path
      if @site_notice.displayed_at.nil?
        edit_planning_application_site_notice_path(planning_application, site_notice)
      else
        planning_application_site_notice_path(planning_application, site_notice)
      end
    end

    def status_tag_component
      if @site_notice.displayed_at.nil?
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
