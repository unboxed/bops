# frozen_string_literal: true

module TaskListItems
  class ConfirmPressNoticeComponent < TaskListItems::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
      @press_notice = planning_application.press_notice
    end

    private

    attr_reader :planning_application, :press_notice

    def link_text
      "Confirm press notice"
    end

    def link_active?
      press_notice.try(:required)
    end

    def link_path
      return unless link_active?

      edit_planning_application_confirm_press_notice_path(planning_application, press_notice)
    end

    def status_tag_component
      StatusTags::BaseComponent.new(status:)
    end

    def status
      return "not_started" unless press_notice&.press_sent_at
      return "in_progress" unless press_notice.published_at

      "complete"
    end
  end
end
