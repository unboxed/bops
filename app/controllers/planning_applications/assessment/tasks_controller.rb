# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class TasksController < BaseController
      before_action :redirect_to_reference_url

      def index
        @show_sidebar = if use_new_sidebar_layout?(:assessment)
          @planning_application.case_record.tasks.find_by(section: "Assessment")
        end

        respond_to do |format|
          format.html
        end
      end
    end
  end
end
