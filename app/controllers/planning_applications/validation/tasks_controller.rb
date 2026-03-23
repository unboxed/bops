# frozen_string_literal: true

module PlanningApplications
  module Validation
    class TasksController < BaseController
      self.application_section = "Validation"

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
    end
  end
end
