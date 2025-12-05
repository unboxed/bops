# frozen_string_literal: true

module PlanningApplications
  module Validation
    class BaseController < AuthenticationController
      before_action :set_planning_application
      before_action :redirect_to_reference_url
      before_action :show_sidebar

      def index
        redirect_to planning_application_validation_tasks_url(@planning_application)
      end

      private

      def show_sidebar
        @show_sidebar = if @planning_application.pre_application? &&
            Rails.configuration.use_new_sidebar_layout &&
            !BLOCKED_SIDEBAR_EMAILS.include?(current_user&.email)
          @planning_application.case_record.tasks.find_by(section: "Validation")
        end
      end
    end
  end
end
