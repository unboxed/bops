# frozen_string_literal: true

module PlanningApplications
  module Review
    class TasksController < BaseController
      before_action :set_planning_application_constraints, only: %i[index]

      def index
        respond_to do |format|
          format.html
        end
      end

      private

      def set_planning_application_constraints
        @planning_application_constraints = @planning_application.planning_application_constraints
      end
    end
  end
end
