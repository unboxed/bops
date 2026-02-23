# frozen_string_literal: true

module PlanningApplications
  module Validation
    class TasksController < BaseController
      before_action :set_items_counter, only: :index

      def index
        task = @planning_application.case_record.tasks.find_by!(section: "Validation").first_child

        if @planning_application.pre_application?
          redirect_to BopsPreapps::Engine.routes.url_helpers.task_path(@planning_application, task)
        else
          redirect_to task_path(@planning_application, task)
        end
      end

      private

      def planning_applications_scope
        super
      end

      def set_items_counter
        @items_counter = @planning_application.items_counter
      end
    end
  end
end
