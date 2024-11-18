# frozen_string_literal: true

module PlanningApplications
  module Review
    class TasksController < BaseController
      before_action :set_planning_application_constraints, only: %i[index]
      before_action :set_neighbour_review, if: :has_consultation?, only: %i[index]

      def index
        respond_to do |format|
          format.html
        end
      end

      private

      def set_neighbour_review
        @neighbour_review = @planning_application.consultation&.neighbour_review || @planning_application.consultation&.reviews&.new
      end

      def set_planning_application_constraints
        @planning_application_constraints = @planning_application.planning_application_constraints
      end

      def has_consultation?
        @planning_application.application_type.consultation?
      end
    end
  end
end
