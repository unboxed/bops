# frozen_string_literal: true

module Tasks
  class CheckPublicityForm < Form
    self.task_actions = %w[save_and_complete save_draft]

    after_initialize do
      @site_notice = planning_application.site_notices.last
      @press_notice = planning_application.press_notice
    end

    attr_reader :press_notice, :site_notice

    def site_notice_not_required?
      !site_notice&.required? && planning_application.site_notices.any?
    end

    def site_notice_resolved?
      site_notice&.complete?
    end

    def site_notice_url
      task_path(planning_application, slug: "/#{task.parent.full_slug}/site-notice", return_to: task.full_slug)
    end

    def press_notice_url
      task_path(planning_application, slug: "/#{task.parent.full_slug}/press-notice", return_to: task.full_slug)
    end
  end
end
