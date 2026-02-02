# frozen_string_literal: true

module BopsPreapps
  class TasksController < AuthenticationController
    include BopsCore::TasksController

    before_action :set_planning_application
    before_action :show_sidebar
    before_action :show_header
    before_action :redirect_to_review_and_submit_report, only: :show
    before_action :build_form

    private

    def template_for(action)
      %w[bops_preapps bops_core].each do |engine|
        path = "#{engine}/tasks/#{@task.full_slug}/#{action}"
        return path if lookup_context.exists?(path)
      end

      "bops_preapps/tasks/generic/#{action}"
    end

    def build_form
      [BopsPreapps, BopsCore].each do |engine|
        klass = engine::Tasks.form_for(@task.slug)
        next unless klass

        @form = klass.new(@task, params)
        break if @form
      end
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
