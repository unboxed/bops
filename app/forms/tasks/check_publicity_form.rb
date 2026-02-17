# frozen_string_literal: true

module Tasks
  class CheckPublicityForm < Form
    self.task_actions = %w[save_and_complete save_draft]

    after_initialize do
      @site_notice = planning_application.site_notices.last
      @press_notice = planning_application.press_notice
    end

    attr_reader :press_notice, :site_notice
  end
end
