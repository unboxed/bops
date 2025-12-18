# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class TasksController < BaseController
      before_action :redirect_to_reference_url
      before_action :redirect_to_initial_task, when: -> { @planning_application.pre_application? }

      def index
        @show_sidebar = if use_new_sidebar_layout?(:assessment)
          @planning_application.case_record.tasks.find_by(section: "Assessment")
        end

        respond_to do |format|
          format.html
        end
      end

      private

      def redirect_to_initial_task
        task = @planning_application.case_record.tasks.find_by(section: "Assessment")&.first_child

        return unless task

        redirect_to BopsPreapps::Engine.routes.url_helpers.task_path(@planning_application, task)
      end
    end
  end
end
