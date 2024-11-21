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
    end
  end
end
