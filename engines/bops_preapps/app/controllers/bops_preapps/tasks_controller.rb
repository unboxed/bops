# frozen_string_literal: true

module BopsPreapps
  class TasksController < AuthenticationController
    before_action :redirect_to_updated_slug

    include BopsCore::TasksController

    before_action :set_planning_application
    before_action :redirect_to_review_and_submit_report, only: :show
    before_action :build_form
    before_action :show_sidebar
    before_action :show_header

    private

    SLUG_REDIRECTS = {
      "check-and-assess/check-application/check-consultees-consulted" =>
        "check-and-assess/check-application/check-consultees",
      "check-and-assess/assessment-summaries/site-description" =>
        "check-and-assess/assessment-summaries/site-and-surroundings"
    }.freeze

    def redirect_to_updated_slug
      new_slug = SLUG_REDIRECTS[params[:slug]]
      return unless new_slug

      redirect_to request.url.sub(params[:slug], new_slug)
    end

    def set_planning_application
      @planning_application = PlanningApplicationPresenter.new(view_context, @case_record.caseable)
    end

    def template_for(action)
      path = "bops_preapps/tasks/#{@task.full_slug}/#{action}"
      lookup_context.exists?(path) ? path : "bops_preapps/tasks/generic/#{action}"
    end

    def build_form
      klass = BopsPreapps::Tasks.form_for(@task.slug)

      @form = klass.new(@task, params)
    end

    def show_header
      @show_header_bar ||= true
    end

    def show_sidebar
      @show_sidebar ||= @task.top_level_ancestor
    end

    def redirect_to_review_and_submit_report
      return unless @task.slug == "review-and-submit-pre-application"

      redirect_to(
        bops_reports.planning_application_path(
          @planning_application,
          origin: "review_and_submit_pre_application"
        )
      )
    end
  end
end
