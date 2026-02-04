# frozen_string_literal: true

module BopsPreapps
  class TasksController < AuthenticationController
    include BopsCore::TasksController

    def tasks_modules = [BopsPreapps::Tasks, BopsCore::Tasks]

    before_action :set_planning_application
    before_action :show_sidebar
    before_action :show_header
    before_action :redirect_to_review_and_submit_report, only: :show
    before_action :build_form

    private

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
