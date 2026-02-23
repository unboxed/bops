# frozen_string_literal: true

module PlanningApplications
  module Validation
    class BaseController < AuthenticationController
      before_action :set_planning_application
      before_action :redirect_to_reference_url
      before_action :show_sidebar

      def show
        task = @planning_application.case_record.tasks.find_by!(section: "Validation").first_child

        if @planning_application.pre_application?
          redirect_to BopsPreapps::Engine.routes.url_helpers.task_path(@planning_application, task)
        else
          redirect_to task_path(@planning_application, task)
        end
      end

      private

      def show_sidebar
        @show_sidebar = if use_new_sidebar_layout?(@planning_application)
          @planning_application.case_record.tasks.find_by(section: "Validation")
        end
      end
    end
  end
end
