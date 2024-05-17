# frozen_string_literal: true

module PlanningApplications
  module Review
    class BaseController < AuthenticationController
      include CommitMatchable

      before_action :set_planning_application
      before_action :ensure_planning_application_is_validated
      before_action :ensure_user_is_reviewer

      def index
        redirect_to planning_application_review_tasks_url(@planning_application)
      end

      private

      def ensure_planning_application_is_validated
        return if @planning_application.validated?

        redirect_to planning_application_path(@planning_application),
          alert: t("planning_applications.review.base.not_validated")
      end
    end
  end
end
