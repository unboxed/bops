# frozen_string_literal: true

module TaskListItems
  class PressNoticeComponent < TaskListItems::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
      @press_notice = planning_application.press_notice
    end

    private

    attr_reader :planning_application, :press_notice

    def link_text
      "Press notice"
    end

    def link_path
      if press_notice.nil?
        new_planning_application_press_notice_path(planning_application)
      else
        planning_application_press_notice_path(planning_application, press_notice)
      end
    end

    def status_tag_component
      StatusTags::BaseComponent.new(status:)
    end

    def status
      return "not_started" if press_notice.nil?

      "complete"
    end
  end
end