# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class TasksController < BaseController
      before_action :redirect_to_reference_url

      def index
        @show_sidebar = if @planning_application.pre_application? && Rails.configuration.use_new_sidebar_layout && !BLOCKED_SIDEBAR_EMAILS.include?(current_user&.email)
          @planning_application.case_record.tasks.find_by(section: "Assessment")
        end

        respond_to do |format|
          format.html
        end
      end
    end
  end
end
