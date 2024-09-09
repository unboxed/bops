# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class BaseController < AuthenticationController
      include CommitMatchable

      before_action :set_planning_application
      before_action :ensure_planning_application_is_validated

      def index
        redirect_to planning_application_assessment_tasks_url(@planning_application)
      end

      private

      def ensure_planning_application_is_validated
        return if @planning_application.validated?

        redirect_to planning_application_path(@planning_application),
          alert: t("planning_applications.assessment.base.not_validated")
      end

      def ensure_can_assess_planning_application
        render plain: "forbidden", status: :forbidden and return unless @planning_application.can_assess?
      end
    end
  end
end
