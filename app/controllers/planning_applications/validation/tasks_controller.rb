# frozen_string_literal: true

module PlanningApplications
  module Validation
    class TasksController < AuthenticationController
      before_action :set_planning_application
      before_action :set_items_counter, only: :index

      def index
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
