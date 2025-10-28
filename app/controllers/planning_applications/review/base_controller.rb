# frozen_string_literal: true

module PlanningApplications
  module Review
    class BaseController < AuthenticationController
      include CommitMatchable

      before_action :set_planning_application
      before_action :set_planning_application_constraints
      before_action :set_neighbour_review, if: :has_consultation?

      before_action :ensure_planning_application_is_validated
      before_action :ensure_user_is_reviewer
      before_action :ensure_application_is_not_preapp
      before_action :set_consultation, if: :has_consultation?

      def index
        redirect_to planning_application_review_tasks_url(@planning_application)
      end

      private

      def ensure_planning_application_is_validated
        return if @planning_application.validated?

        redirect_to planning_application_path(@planning_application),
          alert: t("planning_applications.review.base.not_validated")
      end

      def ensure_application_is_not_preapp
        return unless @planning_application.pre_application?

        redirect_to bops_reports.planning_application_path(@planning_application)
      end

      def has_consultation?
        @planning_application.application_type.consultation?
      end

      def set_neighbour_review
        @neighbour_review = @planning_application.consultation&.neighbour_review || @planning_application.consultation&.reviews&.new
      end

      def set_planning_application_constraints
        @planning_application_constraints = @planning_application.planning_application_constraints
      end

      def redirect_failed_create_error(error)
        redirect_to planning_application_review_tasks_path(@planning_application), alert: Array.wrap(error).to_sentence
      end

      def redirect_to_review_tasks
        redirect_to planning_application_review_tasks_path(@planning_application)
      end

      def render_review_tasks
        @show_header_bar = false
        render "planning_applications/review/tasks/index"
      end

      def tasks_url(options = {})
        planning_application_review_tasks_url(@planning_application, options)
      end
    end
  end
end
