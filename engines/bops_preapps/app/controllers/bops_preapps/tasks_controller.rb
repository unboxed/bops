# frozen_string_literal: true

module BopsPreapps
  class TasksController < AuthenticationController
    include BopsCore::TasksController

    before_action :set_planning_application
    before_action :redirect_to_review_and_submit_report, only: :show
    before_action :redirect_to_outstanding_red_line_validation_request, only: :show
    before_action :redirect_to_outstanding_fee_validation_request, only: :show
    before_action :build_form
    before_action :show_sidebar
    before_action :show_header

    private

    def set_planning_application
      @planning_application = PlanningApplicationPresenter.new(view_context, @case_record.caseable)
    end

    def template_for(action)
      path = "bops_preapps/tasks/#{@task.full_slug}/#{action}"
      lookup_context.exists?(path) ? path : "bops_preapps/tasks/generic/#{action}"
    end

    def build_form
      klass = BopsPreapps::Tasks.form_for(@task.slug)

      @form = klass.new(@task)
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

    def redirect_to_outstanding_red_line_validation_request
      return unless @task.slug == "check-red-line-boundary"

      validation_request = @planning_application.validation_requests
        .where(type: "RedLineBoundaryChangeValidationRequest")
        .open_or_pending
        .first

      return unless validation_request

      redirect_to main_app.planning_application_validation_validation_request_path(
        @planning_application,
        validation_request
      )
    end

    def redirect_to_outstanding_fee_validation_request
      return unless @task.slug == "check-fee"

      validation_request = @planning_application.fee_change_validation_requests
        .open_or_pending
        .first

      return unless validation_request

      redirect_to main_app.planning_application_validation_validation_request_path(
        @planning_application,
        validation_request
      )
    end
  end
end
