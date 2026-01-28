# frozen_string_literal: true

module PlanningApplications
  module Validation
    class TasksController < BaseController
      before_action :set_items_counter, only: :index
      before_action :redirect_to_initial_task

      def index
        respond_to do |format|
          format.html
        end
      end

      private

      def planning_applications_scope
        super
      end

      def set_items_counter
        @items_counter = @planning_application.items_counter
      end

      def redirect_to_initial_task
        task = @planning_application.case_record.tasks.find_by(section: "Validation")&.first_child

        return unless task

        redirect_to BopsPreapps::Engine.routes.url_helpers.task_path(@planning_application, task) if @planning_application.pre_application?
      end
    end
  end
end
