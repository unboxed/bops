# frozen_string_literal: true

module PlanningApplications
  module Information
    class NeighboursController < BaseController
      def show
        @neighbours = @planning_application.consultation&.neighbours || []
      end
    end
  end
end
