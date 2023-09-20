# frozen_string_literal: true

module TaskListItems
  class SiteNoticeComponent < TaskListItems::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
      @site_notice = @planning_application.site_notices&.last
    end

    private

    def link_text
      "Send site notice"
    end

    def link_path
      new_planning_application_site_notice_path(@planning_application)
    end

    def status_tag_component
      if @site_notice.nil?
        StatusTags::BaseComponent.new(
          status: "not_started"
        )
      elsif @site_notice.required == false || @site_notice.displayed_at.present?
        StatusTags::BaseComponent.new(
          status: "complete"
        )
      else
        StatusTags::BaseComponent.new(
          status: "in_progress"
        )
      end
    end
  end
end
