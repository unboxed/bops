# frozen_string_literal: true

module PlanningApplications
  module Review
    class TasksController < BaseController
      before_action :set_planning_application_constraints
      before_action :set_neighbour_review, if: :has_consultation?

      def index
        respond_to do |format|
          format.html
        end
      end
    end
  end
end
