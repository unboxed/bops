# frozen_string_literal: true

module Tasks
  class CheckPublicityForm < Form
    include AssessmentDetailConcern

    def category = "check_publicity"

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
      task_path(planning_application, slug: "consultees-neighbours-and-publicity/publicity/site-notice", return_to: task.full_slug)
    end

    def site_notice_confirmation_request_url
      task_component_path(planning_application, slug: "consultees-neighbours-and-publicity/publicity/site-notice", id: site_notice.id)
    end

    def press_notice_url
      task_path(planning_application, slug: "consultees-neighbours-and-publicity/publicity/press-notice", return_to: task.full_slug)
    end

    def press_notice_confirmation_request_url
      task_component_path(planning_application, slug: "consultees-neighbours-and-publicity/publicity/press-notice", id: press_notice.id)
    end

    private

    def requires_entry? = false
  end
end
